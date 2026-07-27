import { onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";

interface AiSuggestReplyRequest {
  threadMessages: string[];
  caseSubject: string;
}

interface AiSuggestReplyResponse {
  suggestedReply: string;
}

export const aiSuggestReply = onCall<AiSuggestReplyRequest, AiSuggestReplyResponse>(
  async (request) => {
    const { threadMessages, caseSubject } = request.data;

    logger.info("aiSuggestReply called", { caseSubject, messageCount: threadMessages.length });

    const lastMessage =
      threadMessages.length > 0
        ? threadMessages[threadMessages.length - 1]
        : "";

    // Mock logic: derive advice based on keywords in the last message
    let mockAdvice = "reviewing your case thoroughly";
    if (lastMessage.toLowerCase().includes("urgent") || lastMessage.toLowerCase().includes("asap")) {
      mockAdvice = "escalating this to our priority queue immediately";
    } else if (lastMessage.toLowerCase().includes("refund") || lastMessage.toLowerCase().includes("billing")) {
      mockAdvice = "connecting you with our billing specialist for a full review";
    } else if (lastMessage.toLowerCase().includes("error") || lastMessage.toLowerCase().includes("bug")) {
      mockAdvice = "filing a technical investigation with our engineering team";
    }

    const suggestedReply =
      `Thank you for contacting us about ${caseSubject}. ` +
      `Based on your message, I recommend ${mockAdvice}. ` +
      `Our team will follow up within 24 hours.`;

    logger.info("Suggested reply generated", { suggestedReply });

    return { suggestedReply };
  }
);
