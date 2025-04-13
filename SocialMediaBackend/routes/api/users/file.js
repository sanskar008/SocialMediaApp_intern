const response = {}


response.entityType = (req,res,next)=> {
    try{
        req.body.entityType = req.body.entityType || 'chatMessage'
    }
    catch{
        req.body.entityType = 'chatMessage'
    }
   

    return next()
}

response.response =(req,res,next) => {
    const url = req?._media
    try {
        if(url){
            return res.status(200).json({message: 'File uploaded successfully', data:url});
        }
        return res.status(200).json({ success:false });
    } catch (err) {
        console.error(err);
        res.status(500).json({ success:false , message: "Internal Server Error" });
    }
}

module.exports = response