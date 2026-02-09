export function stringToBoolean(val: any): boolean {
  if (typeof val === "boolean") return val;
  return val === "true" || val === "1";
}
