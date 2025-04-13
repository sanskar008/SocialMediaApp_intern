const { MongoDB } = require("./db");
const { ObjectId } = require("mongodb");
const collectionName = "notifications";

const FIELDS = {
  ID: "_id",
  TYPE: "type", // e.g., like, comment, reply, follow, post
  SENDER: "sender", // { id, name, profilePic }
  RECEIVER_ID: "receiverId",
  DETAILS: "details", // { feedId, commentId, replyId, content, notificationImage, notificationText }
  SEEN: "seen",
  TIMESTAMP: "timestamp",
};

class Notifications extends MongoDB {
  constructor() {
    super();
  }

  async init() {
    if (!this.collection) {
      const db = await super.getDBInstance();
      this.collection = db.collection(collectionName);
    }
  }

  getCollectionInstance() {
    return this.collection;
  }

  /**
   * ✅ Add a new notification
   */
  async addNotification(data) {
    try {

      // Check if a notification with the same headerId already exists
      const existingNotification = await this.collection.findOne({
        [FIELDS.RECEIVER_ID]: data[FIELDS.RECEIVER_ID],
        [`${FIELDS.DETAILS}.headerId`]: data[FIELDS.DETAILS].headerId
    });

    if (existingNotification && data.type != "call") {
        return existingNotification._id.toString(); // Return existing notification ID
    }

      const notification = {
        [FIELDS.TYPE]: data[FIELDS.TYPE],
        [FIELDS.SENDER]: data[FIELDS.SENDER], // { id, name, profilePic }
        [FIELDS.RECEIVER_ID]: data[FIELDS.RECEIVER_ID],
        [FIELDS.DETAILS]: data[FIELDS.DETAILS], // { feedId, commentId, replyId, content, notificationImage, notificationText }
        [FIELDS.SEEN]: false, // Default: unread
        [FIELDS.TIMESTAMP]: Date.now(),
      };

      const result = await this.collection.insertOne(notification);
      return result.insertedId;
    } catch (err) {
      console.error("Error adding notification:", err.message);
      throw new Error("Failed to add notification");
    }
  }

  /**
   * ✅ Get Notifications for a user with pagination
   */
  async getNotifications(receiverId, page = 1, limit = 20) {
    try {
      const skip = (page - 1) * limit;
      const notifications = await this.collection
        .find({ [FIELDS.RECEIVER_ID]: receiverId })
        .sort({ [FIELDS.TIMESTAMP]: -1 }) // Sort by latest first
        .skip(skip)
        .limit(limit)
        .toArray();
      
      const totalCount = await this.collection.countDocuments({ [FIELDS.RECEIVER_ID]: receiverId });
      const unseenCount = await this.collection.countDocuments({ 
        [FIELDS.RECEIVER_ID]: receiverId, 
        [FIELDS.SEEN]: false 
      });

      return { 
        notifications, 
        unseenCount,
        totalCount,
        currentPage: page,
        totalPages: Math.ceil(totalCount / limit),
        hasMore: skip + notifications.length < totalCount
      };
    } catch (err) {
      console.error("Error fetching notifications:", err.message);
      throw new Error("Failed to fetch notifications");
    }
  }

  async getUnseen(receiverId, page = 1, limit = 20) {
    try {
      const skip = (page - 1) * limit;
      const notifications = await this.collection
        .find({ [FIELDS.RECEIVER_ID]: receiverId, [FIELDS.SEEN]: false })
        .sort({ [FIELDS.TIMESTAMP]: -1 })
        .skip(skip)
        .limit(limit)
        .toArray();
      
      const totalCount = await this.collection.countDocuments({ 
        [FIELDS.RECEIVER_ID]: receiverId, 
        [FIELDS.SEEN]: false 
      });

      return {
        notifications,
        totalCount,
        currentPage: page,
        totalPages: Math.ceil(totalCount / limit),
        hasMore: skip + notifications.length < totalCount
      };
    } catch (err) {
      console.error("Error fetching unseen notifications:", err.message);
      throw new Error("Failed to fetch unseen notifications");
    }
  }
  
  async getSeen(receiverId, page = 1, limit = 20) {
    try {
      const skip = (page - 1) * limit;
      const notifications = await this.collection
        .find({ [FIELDS.RECEIVER_ID]: receiverId, [FIELDS.SEEN]: true })
        .sort({ [FIELDS.TIMESTAMP]: -1 })
        .skip(skip)
        .limit(limit)
        .toArray();
      
      const totalCount = await this.collection.countDocuments({ 
        [FIELDS.RECEIVER_ID]: receiverId, 
        [FIELDS.SEEN]: true 
      });

      return {
        notifications,
        totalCount,
        currentPage: page,
        totalPages: Math.ceil(totalCount / limit),
        hasMore: skip + notifications.length < totalCount
      };
    } catch (err) {
      console.error("Error fetching seen notifications:", err.message);
      throw new Error("Failed to fetch seen notifications");
    }
  }
  
  
  /**
   * ✅ Mark Notification as Seen
   */
  async markAsSeen(notificationId) {
    try {
      await this.collection.updateOne(
        { [FIELDS.ID]: new ObjectId(notificationId) },
        { $set: { [FIELDS.SEEN]: true } }
      );
      return true;
    } catch (err) {
      console.error("Error marking notification as seen:", err.message);
      throw new Error("Failed to mark notification as seen");
    }
  }

  /**
   * ✅ Delete Notification
   */
  async deleteNotification(notificationId) {
    try {
      const result = await this.collection.deleteOne({ [FIELDS.ID]: new ObjectId(notificationId) });
      return result.deletedCount > 0;
    } catch (err) {
      console.error("Error deleting notification:", err.message);
      throw new Error("Failed to delete notification");
    }
  }

  async getNotificationById(notificationId) {
    try {
      return await this.collection.findOne({ _id: new ObjectId(notificationId) });
    } catch (err) {
      console.error("Error fetching notification:", err);
      return null;
    }
  }
  
  async markNotificationByIdAsSeen(notificationId) {
    try {
      return await this.collection.updateOne(
        { _id: new ObjectId(notificationId) },
        { $set: { seen: true } }
      );
    } catch (err) {
      console.error("Error marking notification as seen:", err);
      return null;
    }
  }
  
  async deleteNotificationById(notificationId) {
    try {
      const result = await this.collection.deleteOne({ [FIELDS.ID]: new ObjectId(notificationId) });
      return result.deletedCount > 0;
    } catch (err) {
      console.error("Error deleting notification:", err.message);
      throw new Error("Failed to delete notification");
    }
  }
  
  async clearAllNotifications(receiverId) {
    try {
      const result = await this.collection.deleteMany({ [FIELDS.RECEIVER_ID]: receiverId });
      return result.deletedCount;
    } catch (err) {
      console.error("Error clearing notifications:", err.message);
      throw new Error("Failed to clear notifications");
    }
  }
  

  async markNotificationsAsSeen(receiverId) {
    try {
      return await this.collection.updateMany(
        { receiverId, seen: false },
        { $set: { seen: true } }
      );
    } catch (err) {
      console.error("Error marking all notifications as seen:", err);
      return null;
    }
  }
  
  async markAllAsSeen(receiverId) {
    try {
      await this.collection.updateMany(
        { [FIELDS.RECEIVER_ID]: receiverId, [FIELDS.SEEN]: false },
        { $set: { [FIELDS.SEEN]: true } }
      );
    } catch (err) {
      console.error("Error marking all notifications as seen:", err.message);
      throw new Error("Failed to mark all notifications as seen");
    }
  }
  
  /**
   * ✅ Get Unseen Notification Count
   */
  async getUnseenCount(receiverId) {
    try {
      const count = await this.collection.countDocuments({
        [FIELDS.RECEIVER_ID]: receiverId,
        [FIELDS.SEEN]: false,
      });
      return count;
    } catch (err) {
      console.error("Error getting unseen notification count:", err.message);
      throw new Error("Failed to get unseen count");
    }
  }
}

module.exports = {
  Notifications,
  FIELDS,
  instance: new Notifications(),
};
