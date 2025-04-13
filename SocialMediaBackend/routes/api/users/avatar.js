const male = [
        // {
        //     "url": "https://media-servicetesting.s3.amazonaws.com/maleAvatars/6782b049398b8c76879dece7/face5.png",
        //     "type": "image"
        // },
        {
            "url": "https://media-servicetesting.s3.amazonaws.com/maleAvatars/6782b049398b8c76879dece7/Screenshot%202025-01-21%20at%208.08.26%C3%A2%C2%80%C2%AFPM.png",
            "type": "image"
        },
        {
            "url": "https://media-servicetesting.s3.amazonaws.com/maleAvatars/6782b049398b8c76879dece7/Screenshot%202025-01-21%20at%208.08.50%C3%A2%C2%80%C2%AFPM.png",
            "type": "image"
        },
        {
            "url": "https://media-servicetesting.s3.amazonaws.com/maleAvatars/6782b049398b8c76879dece7/Screenshot%202025-01-21%20at%208.09.07%C3%A2%C2%80%C2%AFPM.png",
            "type": "image"
        },
        {
            "url": "https://media-servicetesting.s3.amazonaws.com/maleAvatars/6782b049398b8c76879dece7/Screenshot%202025-01-21%20at%208.09.15%C3%A2%C2%80%C2%AFPM.png",
            "type": "image"
        },
        {
            "url": "https://media-servicetesting.s3.ap-south-1.amazonaws.com/maleAvatars/6782b049398b8c76879dece7/Screenshot%202025-01-21%20at%208.09.41%C3%A2%C2%80%C2%AFPM.png",
            "type": "image"
        },
        {
            "url": "https://media-servicetesting.s3.ap-south-1.amazonaws.com/maleAvatars/6782b049398b8c76879dece7/Screenshot%202025-01-21%20at%208.09.55%C3%A2%C2%80%C2%AFPM.png",
            "type": "image"
        },
        {
            "url": "https://media-servicetesting.s3.ap-south-1.amazonaws.com/maleAvatars/6782b049398b8c76879dece7/Screenshot%202025-01-21%20at%208.10.10%C3%A2%C2%80%C2%AFPM.png",
            "type": "image"
        },
        {
            "url": "https://media-servicetesting.s3.ap-south-1.amazonaws.com/maleAvatars/6782b049398b8c76879dece7/Screenshot%202025-01-21%20at%208.10.28%C3%A2%C2%80%C2%AFPM.png",
            "type": "image"
        },
        {
            "url": "https://media-servicetesting.s3.ap-south-1.amazonaws.com/maleAvatars/6782b049398b8c76879dece7/Screenshot%202025-01-21%20at%208.10.34%C3%A2%C2%80%C2%AFPM.png",
            "type": "image"
        },
        {
            "url": "https://media-servicetesting.s3.amazonaws.com/maleAvatars/6782b049398b8c76879dece7/faceLatest.png",
            "type": "image"
        }
    ]
const female =  [
        {
            "url": "https://media-servicetesting.s3.ap-south-1.amazonaws.com/femaleAvatars/6782b049398b8c76879dece7/face1.png",
            "type": "image"
        },
        // {
        //     "url": "https://media-servicetesting.s3.ap-south-1.amazonaws.com/femaleAvatars/6782b049398b8c76879dece7/face30.png",
        //     "type": "image"
        // },
        {
            "url": "https://media-servicetesting.s3.ap-south-1.amazonaws.com/femaleAvatars/6782b049398b8c76879dece7/face34.png",
            "type": "image"
        },
        {
            "url": "https://media-servicetesting.s3.ap-south-1.amazonaws.com/femaleAvatars/6782b049398b8c76879dece7/Screenshot%202025-01-21%20at%208.11.07%C3%A2%C2%80%C2%AFPM.png",
            "type": "image"
        },
        {
            "url": "https://media-servicetesting.s3.ap-south-1.amazonaws.com/femaleAvatars/6782b049398b8c76879dece7/Screenshot%202025-01-21%20at%208.11.14%C3%A2%C2%80%C2%AFPM.png",
            "type": "image"
        },
        {
            "url": "https://media-servicetesting.s3.ap-south-1.amazonaws.com/femaleAvatars/6782b049398b8c76879dece7/Screenshot%202025-01-21%20at%208.11.23%C3%A2%C2%80%C2%AFPM.png",
            "type": "image"
        },
        {
            "url": "https://media-servicetesting.s3.ap-south-1.amazonaws.com/femaleAvatars/6782b049398b8c76879dece7/Screenshot%202025-01-21%20at%208.11.46%C3%A2%C2%80%C2%AFPM.png",
            "type": "image"
        },
        {
            "url": "https://media-servicetesting.s3.ap-south-1.amazonaws.com/femaleAvatars/6782b049398b8c76879dece7/Screenshot%202025-01-21%20at%208.12.02%C3%A2%C2%80%C2%AFPM.png",
            "type": "image"
        },
        {
            "url": "https://media-servicetesting.s3.ap-south-1.amazonaws.com/femaleAvatars/6782b049398b8c76879dece7/Screenshot%202025-01-21%20at%208.12.20%C3%A2%C2%80%C2%AFPM.png",
            "type": "image"
        },
        {
            "url": "https://media-servicetesting.s3.ap-south-1.amazonaws.com/femaleAvatars/6782b049398b8c76879dece7/Screenshot%202025-01-21%20at%208.20.31%C3%A2%C2%80%C2%AFPM%201.png",
            "type": "image"
        },
        {
            "url": "https://media-servicetesting.s3.amazonaws.com/femaleAvatars/6782b049398b8c76879dece7/face30.png",
            "type": "image"
        }
    ]

const avatar = {};

avatar.sendLinks = async (req,res,next) => {
    return res.status(200).json({success : true , URLS : {male,female}})
}

module.exports = avatar;