package com.mhmgad.awqat.android

import android.os.Bundle
import android.view.View
import androidx.appcompat.app.AppCompatActivity
import com.mhmgad.awqat.android.databinding.ActivityMainBinding
import java.util.concurrent.Executors

class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding
    private val io = Executors.newSingleThreadExecutor()
    private var times: MosqueTimes? = null
    private var wear: WearEngineSync? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        val saved = getSharedPreferences(PREFS, MODE_PRIVATE).getString(KEY_QUERY, "lille").orEmpty()
        binding.query.setText(saved)
        binding.status.text = getString(R.string.status_idle)

        binding.load.setOnClickListener { loadMosque() }
        binding.sync.setOnClickListener { syncWatch() }

        wear = runCatching { WearEngineSync(this) }.getOrNull()
        wear?.requestPermission { granted ->
            runOnUiThread {
                if (!granted) {
                    binding.status.text = getString(R.string.status_permission)
                    return@runOnUiThread
                }
                wear?.listenForWatch {
                    runOnUiThread { syncWatch() }
                }
            }
        }
        if (wear == null) {
            binding.status.text = getString(R.string.status_no_wear_engine)
        }
    }

    private fun loadMosque() {
        val query = binding.query.text?.toString().orEmpty()
        binding.status.text = getString(R.string.status_loading)
        binding.sync.isEnabled = false
        io.execute {
            try {
                val result = MawaqitClient.load(query)
                times = result
                getSharedPreferences(PREFS, MODE_PRIVATE)
                    .edit()
                    .putString(KEY_QUERY, query)
                    .apply()
                runOnUiThread { showTimes(result) }
            } catch (error: Exception) {
                runOnUiThread {
                    binding.sync.isEnabled = false
                    binding.status.text = error.message ?: error.javaClass.simpleName
                    binding.times.text = ""
                }
            }
        }
    }

    private fun showTimes(result: MosqueTimes) {
        binding.mosqueName.text = result.name
        binding.times.text = getString(
            R.string.times_block,
            result.date,
            result.fajr,
            result.dhuhr,
            result.jumua,
            result.asr,
            result.maghrib,
            result.isha
        )
        binding.sync.isEnabled = true
        binding.status.text = getString(R.string.status_loaded)
        binding.sync.visibility = View.VISIBLE
    }

    private fun syncWatch() {
        val payload = times?.toWatchJson()
        val client = wear
        if (payload == null) {
            binding.status.text = getString(R.string.status_load_first)
            return
        }
        if (client == null) {
            binding.status.text = getString(R.string.status_no_wear_engine)
            return
        }
        binding.status.text = getString(R.string.status_syncing)
        client.sendTimes(payload) { message ->
            runOnUiThread { binding.status.text = message }
        }
    }

    companion object {
        private const val PREFS = "awqat"
        private const val KEY_QUERY = "query"
    }
}
