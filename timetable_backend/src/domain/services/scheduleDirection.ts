export type OrderedScheduleStop = {
  sequence: number;
  stationName: string;
};

export type ScheduleDirection = {
  nextStation: string;
  destination: string;
};

export const resolveScheduleDirection = (
  currentSequence: number,
  stops: readonly OrderedScheduleStop[],
): ScheduleDirection | null => {
  const ordered = [...stops].sort((a, b) => a.sequence - b.sequence);
  const next = ordered.find((stop) => stop.sequence > currentSequence);
  const destination = ordered.at(-1);
  if (!next || !destination) return null;
  return {
    nextStation: next.stationName,
    destination: destination.stationName,
  };
};

