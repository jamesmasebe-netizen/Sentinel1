/**
 * Unit tests for `askCopilot` (T3-ENGINES).
 *
 * Real Gemini output is inherently unpredictable, so per TEST_STRATEGY.md's AI/IoT guidance this
 * is a contract/shape test, not an output-correctness test: `@google/generative-ai` is mocked so
 * the real API is never called, and assertions check that askCopilot (a) validates before ever
 * touching Gemini, (b) sends the RIGHT model/prompt, and (c) shapes Gemini's response into the
 * right `{ answer, confidence }` contract / error behavior — the same "wrong name/wrong field"
 * class of check this session has repeatedly found real bugs with elsewhere (e.g. T2-BILLING).
 */
const mockGenerateContent = jest.fn();
const mockGetGenerativeModel = jest.fn(() => ({ generateContent: mockGenerateContent }));
const mockGoogleGenerativeAI = jest.fn().mockImplementation(() => ({
  getGenerativeModel: mockGetGenerativeModel,
}));
jest.mock("@google/generative-ai", () => ({
  GoogleGenerativeAI: mockGoogleGenerativeAI,
}));

import firebaseFunctionsTest from "firebase-functions-test";
import type { CallableRequest } from "firebase-functions/v2/https";
import { askCopilot } from "./copilotEngine";

const { wrap } = firebaseFunctionsTest();
const wrapped = wrap(askCopilot);

function buildRequest(data: unknown): CallableRequest {
  const req = {
    data,
    auth: { uid: "test-user-1", token: {} },
    rawRequest: {},
    acceptsStreaming: false,
  };
  return req as unknown as CallableRequest;
}

const ORIGINAL_ENV = process.env;

beforeEach(() => {
  jest.clearAllMocks();
  process.env = { ...ORIGINAL_ENV, GEMINI_API_KEY: "test-api-key" };
});

afterAll(() => {
  process.env = ORIGINAL_ENV;
});

describe("askCopilot — validation (no Gemini call)", () => {
  it("rejects a missing query", async () => {
    await expect(
      wrapped(buildRequest({ screenContext: "Dashboard" }))
    ).rejects.toMatchObject({ code: "invalid-argument" });
    expect(mockGenerateContent).not.toHaveBeenCalled();
  });

  it("rejects an empty/whitespace-only query", async () => {
    await expect(
      wrapped(buildRequest({ query: "   ", screenContext: "Dashboard" }))
    ).rejects.toMatchObject({ code: "invalid-argument" });
    expect(mockGenerateContent).not.toHaveBeenCalled();
  });

  it("rejects a non-string screenContext", async () => {
    await expect(
      wrapped(buildRequest({ query: "How many open incidents?", screenContext: 42 }))
    ).rejects.toMatchObject({ code: "invalid-argument" });
    expect(mockGenerateContent).not.toHaveBeenCalled();
  });
});

describe("askCopilot — missing API key", () => {
  it("fails with an internal error and never calls Gemini when GEMINI_API_KEY is unset", async () => {
    delete process.env.GEMINI_API_KEY;

    await expect(
      wrapped(buildRequest({ query: "Hello", screenContext: "Dashboard" }))
    ).rejects.toMatchObject({ code: "internal" });
    expect(mockGoogleGenerativeAI).not.toHaveBeenCalled();
  });
});

describe("askCopilot — successful Gemini response", () => {
  it("sends the trimmed query/context to gemini-1.5-flash and returns { answer, confidence }", async () => {
    mockGenerateContent.mockResolvedValue({
      response: {
        text: () => "  You have 4 open incidents.  ",
        candidates: [{ avgLogprobs: -1 }], // -> confidence 0.9 exactly
      },
    });

    const result = (await wrapped(
      buildRequest({ query: "  How many open incidents?  ", screenContext: "  Dashboard  " })
    )) as { answer: string; confidence: number };

    expect(result.answer).toBe("You have 4 open incidents.");
    expect(result.confidence).toBe(0.9);

    expect(mockGetGenerativeModel).toHaveBeenCalledWith({ model: "gemini-1.5-flash" });
    const prompt = mockGenerateContent.mock.calls[0][0] as string;
    expect(prompt).toContain("How many open incidents?");
    expect(prompt).toContain("Dashboard");
  });

  it("defaults confidence to 0.92 when the response has no candidates/avgLogprobs", async () => {
    mockGenerateContent.mockResolvedValue({
      response: { text: () => "An answer.", candidates: [] },
    });

    const result = (await wrapped(
      buildRequest({ query: "Hello", screenContext: "Dashboard" })
    )) as { confidence: number };

    expect(result.confidence).toBe(0.92);
  });

  it("clamps confidence to the [0, 1] range", async () => {
    mockGenerateContent.mockResolvedValue({
      response: { text: () => "An answer.", candidates: [{ avgLogprobs: 50 }] }, // would be >1 unclamped
    });

    const result = (await wrapped(
      buildRequest({ query: "Hello", screenContext: "Dashboard" })
    )) as { confidence: number };

    expect(result.confidence).toBeLessThanOrEqual(1);
  });
});

describe("askCopilot — Gemini failure handling", () => {
  it("rejects with an internal error when Gemini returns an empty answer", async () => {
    mockGenerateContent.mockResolvedValue({
      response: { text: () => "   ", candidates: [] },
    });

    await expect(
      wrapped(buildRequest({ query: "Hello", screenContext: "Dashboard" }))
    ).rejects.toMatchObject({ code: "internal" });
  });

  it("wraps a thrown Gemini error into an internal HttpsError including the original message", async () => {
    mockGenerateContent.mockRejectedValue(new Error("quota exceeded"));

    await expect(
      wrapped(buildRequest({ query: "Hello", screenContext: "Dashboard" }))
    ).rejects.toMatchObject({
      code: "internal",
      message: expect.stringContaining("quota exceeded"),
    });
  });
});
