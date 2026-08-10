/**
 * Unit tests for `suggestReplyTemplate` (T3-ENGINES; renamed from `aiSuggestReply` — see
 * docs/testing/TEST_BACKLOG.md's "Flagged-not-fixed follow-up pass" entry). This is NOT an AI call
 * — no LLM, no external API, no Firestore. It's a fully deterministic keyword-matcher
 * (`urgent`/`asap` -> escalate, `refund`/`billing` -> billing specialist, `error`/`bug` ->
 * engineering, else a generic "reviewing your case thoroughly") wrapped in a templated sentence.
 * Confirmed to have zero call sites anywhere in the Flutter app, so it isn't currently shown to any
 * real customer_service agent — the old `aiSuggestReply` name was still misleading to any future
 * caller/reader, hence the rename (compare `copilotEngine.ts`'s `askCopilot`, which does call a
 * real model). Because the logic is fully deterministic, this file tests real output correctness
 * (not just contract shape) — unlike `copilotEngine.test.ts`, where the real answer text is
 * inherently unpredictable and only response *shape* can be asserted.
 */
import firebaseFunctionsTest from "firebase-functions-test";
import type { CallableRequest } from "firebase-functions/v2/https";
import { suggestReplyTemplate } from "./aiEngine";

const { wrap } = firebaseFunctionsTest();
const wrapped = wrap(suggestReplyTemplate);

function buildRequest(data: unknown): CallableRequest {
  const req = {
    data,
    auth: { uid: "test-user-1", token: {} },
    rawRequest: {},
    acceptsStreaming: false,
  };
  return req as unknown as CallableRequest;
}

describe("suggestReplyTemplate — deterministic keyword-based reply (not a real AI call)", () => {
  it("defaults to a generic 'reviewing' reply when no keyword matches", async () => {
    const result = (await wrapped(
      buildRequest({ threadMessages: ["Hi, just checking in on my order."], caseSubject: "Order status" })
    )) as { suggestedReply: string };

    expect(result.suggestedReply).toContain("Order status");
    expect(result.suggestedReply).toContain("reviewing your case thoroughly");
  });

  it("escalates when the last message contains 'urgent'", async () => {
    const result = (await wrapped(
      buildRequest({ threadMessages: ["This is urgent, please help!"], caseSubject: "Login issue" })
    )) as { suggestedReply: string };

    expect(result.suggestedReply).toContain("escalating this to our priority queue immediately");
  });

  it("escalates when the last message contains 'asap' (case-insensitive)", async () => {
    const result = (await wrapped(
      buildRequest({ threadMessages: ["Need this fixed ASAP"], caseSubject: "Access request" })
    )) as { suggestedReply: string };

    expect(result.suggestedReply).toContain("escalating this to our priority queue immediately");
  });

  it("routes to billing when the last message mentions 'refund'", async () => {
    const result = (await wrapped(
      buildRequest({ threadMessages: ["I want a refund"], caseSubject: "Charge dispute" })
    )) as { suggestedReply: string };

    expect(result.suggestedReply).toContain("connecting you with our billing specialist");
  });

  it("routes to engineering when the last message mentions 'bug'", async () => {
    const result = (await wrapped(
      buildRequest({ threadMessages: ["Found a bug in the app"], caseSubject: "App crash" })
    )) as { suggestedReply: string };

    expect(result.suggestedReply).toContain("filing a technical investigation with our engineering team");
  });

  it("only inspects the LAST message in the thread, not earlier ones", async () => {
    const result = (await wrapped(
      buildRequest({
        threadMessages: ["This is urgent!", "Actually never mind, just a general question."],
        caseSubject: "General",
      })
    )) as { suggestedReply: string };

    // The urgent keyword was in the FIRST message only — the last message has no keyword match.
    expect(result.suggestedReply).toContain("reviewing your case thoroughly");
    expect(result.suggestedReply).not.toContain("escalating");
  });

  it("treats an empty thread as an empty last message (falls back to the generic reply)", async () => {
    const result = (await wrapped(
      buildRequest({ threadMessages: [], caseSubject: "New case" })
    )) as { suggestedReply: string };

    expect(result.suggestedReply).toContain("reviewing your case thoroughly");
  });
});
