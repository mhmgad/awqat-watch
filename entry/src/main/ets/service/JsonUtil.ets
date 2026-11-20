export function parseObject(text: string): Record<string, Object> {
  const parsed = JSON.parse(text);
  if (parsed === null || typeof parsed !== 'object' || parsed instanceof Array) {
    return {};
  }
  return parsed as Record<string, Object>;
}

export function asObject(value: Object | string | number | boolean | null | undefined): Record<string, Object> {
  if (value === null || value === undefined) {
    return {};
  }
  if (typeof value === 'string') {
    return parseObject(value);
  }
  if (typeof value === 'object' && !(value instanceof Array)) {
    return value as Record<string, Object>;
  }
  return {};
}

export function asArray(value: Object | string | number | boolean | null | undefined): Object[] {
  if (value instanceof Array) {
    return value as Object[];
  }
  return [];
}

export function strVal(obj: Record<string, Object>, key: string, fallback: string = ''): string {
  const value = obj[key];
  if (typeof value === 'string') {
    return value;
  }
  if (typeof value === 'number' || typeof value === 'boolean') {
    return `${value}`;
  }
  return fallback;
}

export function numVal(obj: Record<string, Object>, key: string, fallback: number = 0): number {
  const value = obj[key];
  if (typeof value === 'number') {
    return value;
  }
  if (typeof value === 'string') {
    const parsed = Number(value);
    return Number.isNaN(parsed) ? fallback : parsed;
  }
  return fallback;
}

export function boolVal(obj: Record<string, Object>, key: string): boolean {
  const value = obj[key];
  if (typeof value === 'boolean') {
    return value;
  }
  if (typeof value === 'number') {
    return value !== 0;
  }
  if (typeof value === 'string') {
    return value !== '' && value !== '0' && value !== 'false';
  }
  return false;
}
