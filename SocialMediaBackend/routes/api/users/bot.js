const { users : usersMongo } = require('../../../db/mongo');
const { FIELDS } = require('../../../db/mongo/users');
const botUser = {}

botUser.check = async (req, res, next) => {
    console.log('hello')
    try{
        const bot = await usersMongo.instance.checkBot();
        if(bot){
            return res.status(200).json({success: true , message : 'Bot already exist', data : bot})
        }
        return next()
    }
    catch{
        return res.status(400).json({success:false, message : 'Error Occurred'})
    }
}

botUser.validateBody = (req, res, next) => {
    const { profilePic , name , nickName , status } = req.body;

    if (!name || !nickName || !profilePic || !status) {
        return res.status(400).json({ message: 'Missing JSON Body' });
    }

    next();
}

botUser.createBot = async (req, res, next) => {
    const { profilePic , name , nickName , status } = req.body;

    try{
        const data = {
            [FIELDS.PROFILE_PIC] : profilePic,
            [FIELDS.NAME] : name,
            [FIELDS.NICKNAME] : nickName,
            [FIELDS.STATUS] : status,
            [FIELDS.IS_BOT] : true,
            [FIELDS.PRIVACY_LEVEL]:0
        }
        const bot = await usersMongo.instance.createUser(data);
        console.log(bot)
      
        return res.status(200).json({success: true , message : 'Bot created successfully' , data : data})
    }
    catch(err){
        console.log(err);
    }
}

botUser.getDetails = async(req,res,next) => {
    try{
        const bot = await usersMongo.instance.checkBot();
        if(bot){
            return res.status(200).json({success: true , message : 'Bot already exist', data : bot})
        }
        return res.status(400).json({success:false, message : 'Bot does not exist'})
    }
    catch{
        return res.status(400).json({success:false, message : 'Error Occurred'})
    }
}

module.exports = botUser;