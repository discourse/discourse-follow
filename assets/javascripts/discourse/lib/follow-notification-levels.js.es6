import { buttonDetails} from "discourse/lib/notification-levels";

const MUTED = 0;
const REGULAR = 1;
const TRACKING = 2;
const WATCHING = 3;
const WATCHING_FIRST_POST = 4;

export const allLevels = [
  WATCHING,
  TRACKING,
  WATCHING_FIRST_POST,
  REGULAR,
  MUTED,
].map(buttonDetails);

export const followLevels = allLevels.filter(
  (l) => (l.id !== MUTED  && l.id !== TRACKING)
);