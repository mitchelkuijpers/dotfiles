import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import type { Api, Model } from "@earendil-works/pi-ai";
import { getBuiltinModels, getBuiltinProviders, type BuiltinProvider } from "@earendil-works/pi-ai/providers/all";
import type { ExtensionAPI, ProviderChatModelConfig } from "@earendil-works/pi-coding-agent";

const gatewayUrl = "http://127.0.0.1:18766/v1";
const tokenPath = join(homedir(), ".omp", "auth-gateway.token");
const defaultModelId = "openai-codex/gpt-6-sol";
const builtinProviders = new Set<string>(getBuiltinProviders());

interface GatewayModel {
  id?: string;
  api?: string;
  kind?: string;
  display_name?: string;
  input_modalities?: string[];
  context_length?: number;
  max_output_tokens?: number;
  supports_tools?: boolean;
}

async function discoverModels(signal?: AbortSignal): Promise<ProviderChatModelConfig[]> {
  const requestSignal = signal
    ? AbortSignal.any([signal, AbortSignal.timeout(5000)])
    : AbortSignal.timeout(5000);
  const token = (await readFile(tokenPath, { encoding: "utf8", signal: requestSignal })).trim();
  if (!token) throw new Error("OMP gateway token is empty");
  const response = await fetch(`${gatewayUrl}/models`, {
    headers: { Authorization: `Bearer ${token}` },
    signal: requestSignal,
  });
  if (!response.ok) throw new Error(`OMP gateway model discovery failed: HTTP ${response.status}`);

  const payload = (await response.json()) as { data?: GatewayModel[] };
  if (!Array.isArray(payload?.data)) throw new Error("OMP gateway returned an invalid model catalog");

  const catalogs = new Map<string, Model<Api>[]>();
  const models: ProviderChatModelConfig[] = [];
  for (const entry of payload.data) {
    if (
      typeof entry?.id !== "string" ||
      !entry.id.includes("/") ||
      (entry.kind !== undefined && entry.kind !== "chat") ||
      entry.supports_tools === false ||
      !entry.input_modalities?.includes("text")
    ) continue;

    const provider = entry.id.slice(0, entry.id.indexOf("/"));
    const id = entry.id.slice(provider.length + 1);
    if (!provider || !id) continue;
    let catalog = catalogs.get(provider);
    if (!catalog && builtinProviders.has(provider)) {
      catalog = getBuiltinModels(provider as BuiltinProvider);
      catalogs.set(provider, catalog);
    }
    const known = catalog?.find((model) => model.id === id);
    const contextWindow = entry.context_length ?? known?.contextWindow;
    const maxTokens = entry.max_output_tokens ?? known?.maxTokens;
    if (!contextWindow || !maxTokens) continue;

    // Codex's native Pi adapter requires Codex OAuth; the gateway instead
    // accepts its own bearer token and exposes these models via /v1/responses.
    // Other gateway chat models use its OpenAI-compatible completions route,
    // regardless of the upstream API advertised in the catalog.
    if (typeof entry.api !== "string") continue;
    const api = entry.api === "openai-codex-responses" || entry.api === "openai-responses"
      ? "openai-responses"
      : "openai-completions";

    models.push({
      id: entry.id,
      name: entry.display_name ?? known?.name ?? entry.id,
      api,
      reasoning: known?.reasoning ?? false,
      thinkingLevelMap: known?.thinkingLevelMap,
      input: entry.input_modalities.includes("image") ? ["text", "image"] : ["text"],
      // Pi requires rates even when neither the gateway nor Pi has prices.
      cost: known?.cost ?? { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
      contextWindow,
      maxTokens,
    });
  }
  if (!models.some((model) => model.id === defaultModelId)) {
    throw new Error(`OMP gateway does not offer the default model ${defaultModelId}`);
  }
  return models;
}

export default async function (pi: ExtensionAPI) {
  // Pi awaits async extension factories before resolving the startup model.
  // An offline refresh retains the catalog fetched here without another request.
  let models = await discoverModels();
  pi.registerProvider("omp-gateway", {
    name: "OMP Auth Gateway",
    baseUrl: gatewayUrl,
    apiKey: '!cat "$HOME/.omp/auth-gateway.token"',
    authHeader: true,
    models,
    refreshModels: async (context) => {
      if (context.allowNetwork) models = await discoverModels(context.signal);
      return models;
    },
  });
}
