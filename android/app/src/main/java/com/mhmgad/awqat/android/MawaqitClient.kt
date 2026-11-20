package com.mhmgad.awqat.android

import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.Calendar
import java.util.Locale

data class MosqueTimes(
    val slug: String,
    val name: String,
    val date: String,
    val fajr: String,
    val dhuhr: String,
    val jumua: String,
    val asr: String,
    val maghrib: String,
    val isha: String
) {
    fun toWatchJson(): String {
        val json = JSONObject()
        json.put("v", 1)
        json.put("n", name)
        json.put("s", slug)
        json.put("d", date)
        json.put("f", fajr)
        json.put("h", dhuhr)
        json.put("j", jumua)
        json.put("a", asr)
        json.put("m", maghrib)
        json.put("i", isha)
        return json.toString()
    }
}

class MawaqitException(message: String) : Exception(message)

object MawaqitClient {
    private const val PAGE_BASE = "https://mawaqit.net/en"

    fun load(query: String): MosqueTimes {
        val slug = slugCandidates(query).firstOrNull()
            ?: throw MawaqitException("Enter a mosque slug or MAWAQIT URL")
        val html = getText("$PAGE_BASE/${slug}")
        val conf = extractConfData(html)
        if (conf.length() == 0) {
            throw MawaqitException("No MAWAQIT timetable for $slug")
        }
        return toTimes(slug, conf)
    }

    internal fun slugCandidates(query: String): List<String> {
        val trimmed = query.trim()
        val fromUrl = slugFromMawaqitUrl(trimmed)
        val raw = if (fromUrl.isNotEmpty()) fromUrl else trimmed
        val slug = slugify(raw)
        return if (slug.isEmpty()) emptyList() else listOf(slug)
    }

    private fun slugFromMawaqitUrl(text: String): String {
        val marker = "mawaqit.net/"
        val idx = text.indexOf(marker)
        if (idx < 0) return ""
        var rest = text.substring(idx + marker.length)
        val queryAt = rest.indexOf('?')
        if (queryAt >= 0) rest = rest.substring(0, queryAt)
        val parts = rest.split('/').filter { it.isNotEmpty() }
        if (parts.size >= 3 && parts[1] == "m") return parts[2]
        if (parts.size >= 2) return parts[1]
        if (parts.size == 1) return parts[0]
        return ""
    }

    private fun slugify(value: String): String {
        val folded = foldAccents(value.trim().lowercase(Locale.ROOT))
        return folded.replace(Regex("[^a-z0-9]+"), "-").trim('-')
    }

    private fun foldAccents(value: String): String {
        val from = "àáâäãåèéêëìíîïòóôöõùúûüçñ"
        val to = "aaaaaaeeeeiiiiooooouuuucn"
        val out = StringBuilder()
        for (ch in value) {
            val at = from.indexOf(ch)
            out.append(if (at >= 0) to[at] else ch)
        }
        return out.toString()
    }

    internal fun extractConfData(html: String): JSONObject {
        val idx = html.indexOf("confData")
        if (idx < 0) return JSONObject()
        val start = html.indexOf('{', idx)
        if (start < 0) return JSONObject()
        var depth = 0
        var inString = false
        var escape = false
        var quote = ' '
        for (i in start until html.length) {
            val ch = html[i]
            if (inString) {
                if (escape) {
                    escape = false
                } else if (ch == '\\') {
                    escape = true
                } else if (ch == quote) {
                    inString = false
                }
                continue
            }
            if (ch == '"' || ch == '\'') {
                inString = true
                quote = ch
                continue
            }
            if (ch == '{') {
                depth += 1
            } else if (ch == '}') {
                depth -= 1
                if (depth == 0) {
                    return JSONObject(html.substring(start, i + 1))
                }
            }
        }
        return JSONObject()
    }

    private fun toTimes(slug: String, conf: JSONObject): MosqueTimes {
        val now = Calendar.getInstance()
        val clocks = clocksFromConf(conf, now)
        val name = conf.optString("label").ifBlank { conf.optString("name") }.ifBlank { slug }
        return MosqueTimes(
            slug = slug,
            name = name,
            date = String.format(
                Locale.US,
                "%04d-%02d-%02d",
                now.get(Calendar.YEAR),
                now.get(Calendar.MONTH) + 1,
                now.get(Calendar.DAY_OF_MONTH)
            ),
            fajr = clocks.getValue("fajr"),
            dhuhr = clocks.getValue("dhuhr"),
            jumua = clocks.getValue("jumua"),
            asr = clocks.getValue("asr"),
            maghrib = clocks.getValue("maghrib"),
            isha = clocks.getValue("isha")
        )
    }

    private fun clocksFromConf(conf: JSONObject, now: Calendar): Map<String, String> {
        val clocks = mutableMapOf(
            "fajr" to "--:--",
            "dhuhr" to "--:--",
            "asr" to "--:--",
            "maghrib" to "--:--",
            "isha" to "--:--",
            "jumua" to "--:--"
        )
        val row = todayRow(conf, now)
        if (row.size >= 6) {
            val offset = if (row.size == 7) 1 else 0
            clocks["fajr"] = row[offset]
            clocks["dhuhr"] = row[offset + 2]
            clocks["asr"] = row[offset + 3]
            clocks["maghrib"] = row[offset + 4]
            clocks["isha"] = row[offset + 5]
        } else {
            val times = stringRow(conf.opt("times"))
            if (times.size >= 5) {
                clocks["fajr"] = times[0]
                clocks["dhuhr"] = times[1]
                clocks["asr"] = times[2]
                clocks["maghrib"] = times[3]
                clocks["isha"] = times[4]
            }
        }
        if (conf.optBoolean("jumuaAsDuhr")) {
            clocks["jumua"] = clocks.getValue("dhuhr")
        } else {
            val jumua = conf.optString("jumua")
            clocks["jumua"] = if (jumua.isNotBlank()) jumua else clocks.getValue("dhuhr")
        }
        return clocks
    }

    private fun todayRow(conf: JSONObject, now: Calendar): List<String> {
        val calendar = conf.optJSONArray("calendar") ?: return emptyList()
        if (calendar.length() < 12) return emptyList()
        val month = calendar.optJSONObject(now.get(Calendar.MONTH)) ?: return emptyList()
        return stringRow(month.opt(now.get(Calendar.DAY_OF_MONTH).toString()))
    }

    private fun stringRow(value: Any?): List<String> {
        val list = mutableListOf<String>()
        when (value) {
            is JSONArray -> {
                for (i in 0 until value.length()) {
                    list.add(value.optString(i))
                }
            }
            is Collection<*> -> value.forEach { list.add(it?.toString() ?: "") }
        }
        return list
    }

    private fun getText(url: String): String {
        val connection = URL(url).openConnection() as HttpURLConnection
        connection.connectTimeout = 15000
        connection.readTimeout = 20000
        connection.setRequestProperty("Accept", "text/html")
        connection.setRequestProperty("User-Agent", "AwqatWatch/1.0")
        try {
            val code = connection.responseCode
            val body = (if (code >= 400) connection.errorStream else connection.inputStream)
                ?.bufferedReader()
                ?.use { it.readText() }
                ?: ""
            if (code >= 400) {
                throw MawaqitException("HTTP $code for $url")
            }
            return body
        } finally {
            connection.disconnect()
        }
    }
}
