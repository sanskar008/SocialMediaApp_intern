const moment = require("moment");
const { Feeds } = require("../db/mongo/feeds"); // Assuming Feeds is your class to handle database operations



// Function to generate the weekId for each week of 2025
const buildWeekIdForDate = (date) => {
  if (!date) {
    throw new TypeError('Invalid argument date');
  }
  const _moment = moment(date, 'YYYY-MM-DD', true);
  if (!_moment.isValid()) {
    throw new TypeError('Invalid date format. Expected YYYY-MM-DD');
  }
  let year = moment(date).format('YYYY');
  let month = moment(date).format('MM');
  let week = moment(date).format('WW');
  if (month === "12" && week === 1) {
    year += 1;
  }
  return `${year}-${week}`;
};

// Function to create all indices for 2025
const createIndicesFor2025 = async () => {
  const startOfYear = moment('2025-01-01'); // Starting from January 1, 2025
  const endOfYear = moment('2025-01-04'); // Ending on December 31, 2025

  // Loop through every week of the year 2025
  for (let date = startOfYear; date.isBefore(endOfYear); date.add(1, 'week')) {
    const weekId = buildWeekIdForDate(date.format('YYYY-MM-DD'));
    const feedInstance = new Feeds(`feeds-${weekId}`, date.format('YYYY-MM-DD'));
    console.log(feedInstance)
    try {
      await feedInstance.init(); // Ensure the collection is initialized
      await feedInstance.createIndex(`feeds-${weekId}`); // Create index for the week
      
      console.log(feedInstance);
    } catch (err) {
      console.error(`Error creating index for ${weekId}:`, err);
    }
  }
};

// Run the script to create indices
createIndicesFor2025();
