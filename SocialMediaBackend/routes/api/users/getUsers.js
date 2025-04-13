const { users: usersMongo } = require('../../../db/mongo');

const getUsers = {};

getUsers.validateRequest = (req, res, next) => {
  const { page, limit } = req.query;
  let pageNum = 1;
  let limitNum = 10;

  if (page !== undefined) {
    if (isNaN(page) || parseInt(page, 10) < 1) {
      return res.status(400).json({ message: "Invalid 'page' parameter. It must be a positive integer." });
    }
    pageNum = parseInt(page, 10);
  }

  if (limit !== undefined) {
    if (isNaN(limit) || parseInt(limit, 10) < 1) {
      return res.status(400).json({ message: "Invalid 'limit' parameter. It must be a positive integer." });
    }
    limitNum = parseInt(limit, 10);
  }

  req.pagination = { page: pageNum, limit: limitNum };
  return next();
};

getUsers.getThem = async (req, res, next) => {
  try {
    const { page, limit } = req.pagination;
    const usersList = await usersMongo.instance.getUsers(page, limit);
    req.usersData = usersList;
    return next();
  } catch (error) {
    console.error("Error fetching users:", error.message);
    return next({ status: 500, message: "Internal Server Error" });
  }
};

getUsers.buildResponse = (req, res) => {
  return res.status(200).json({ success: true, data: req.usersData });
};

module.exports = getUsers;