const axios = require('axios');
const { PREDEFINED_INTERESTS } = require('../../constants/interests');

const checkIfUserShowedInterest = async (userMessage) => {
    const response = await axios.post("https://api.openai.com/v1/chat/completions", {
        model: "gpt-4o-mini",
        messages: [
            {
                "role": "system",
                "content": [
                    {
                        "type": "text",
                        "text": "You will analyze user message to detect interest in specific activities from our predefined list. Your task is to determine:\n1) If the user showed interest in an activity that matches our predefined interests\n2) If the user explicitly asked for friend recommendations related to that interest\n\nOnly return interests from the predefined list. Be precise in your assessment."
                    }
                ]
            },
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": `Analyze the following message and determine if the user expresses interest in any of our predefined topics. If yes, identify the most relevant interest(s) and whether they explicitly asked to connect with others who share this interest.\n\nUser message: "${userMessage}"\n\nPredefined Interests: [${PREDEFINED_INTERESTS.join(',')}]\n\nReturn the closest matching interest(s) (max 2 if absolutely necessary, comma-separated). Set didUserAskForFriends to true ONLY if they explicitly asked for connections/friends with similar interests. give interest only and only from predefined interest list`
                    }
                ]
            }
        ],
        response_format: {
            "type": "json_schema",
            "json_schema": {
                "name": "recommended_friends",
                "strict": true,
                "schema": {
                    "type": "object",
                    "properties": {
                        "data": {
                            "type": "object",
                            "description": "A list of interest.",
                            "properties": {
                                "interest": {
                                    "type": "string",
                                    "description": `The type of interest. Give interest(s) out of - ${PREDEFINED_INTERESTS.join(',')} Pick only closest interest. Return comma-separated 2 interests if ABSOLUTELY necessary. Give interest only and only from predefined interest list`
                                },
                                "didUserAskForFriends": {
                                    "type": "boolean",
                                    "description": "Indicates if the user asked for friend recommendations for any of the pre defined interests; for example, 'I love music. Can you recommend me some friends who love music too?' or 'I love to play sports. Can you recommend me some friends who love to play sports too?' will be true; 'I like movies' or 'I sometimes go running' will be false."
                                }
                            },
                            "required": [
                                "interest",
                                "didUserAskForFriends"
                            ],
                            "additionalProperties": false
                        }
                    },
                    "required": [
                        "data"
                    ],
                    "additionalProperties": false
                }
            }
        },
        temperature: 0.3,
        max_completion_tokens: 2048,
        top_p: 1,
        frequency_penalty: 0,
        presence_penalty: 0
    }, {
        headers: {
            "Authorization": `Bearer ${process.env.OPENAI_API_KEY}`,
            "Content-Type": "application/json"
        }
    });

    try {
        // Parse the JSON content from the response
        const content = response.data.choices[0].message.content;
        console.log("openai response", content);
        const parsedResponse = JSON.parse(content);
        return parsedResponse.data;
    } catch (error) {
        console.error("Error parsing OpenAI response:", error);
        return { interest: "", isInterestShown: false };
    }
}

module.exports = {
    checkIfUserShowedInterest
}