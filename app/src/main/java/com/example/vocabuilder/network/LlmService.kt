package com.example.vocabuilder.network

import com.example.vocabuilder.data.PreferencesManager
import com.example.vocabuilder.data.entity.LlmProfile
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.TimeUnit

data class LlmParsedWord(
    val term: String,
    val definition: String,
    val partOfSpeech: String = "",
    val exampleSentence: String = "",
    val category: String = ""
)

class LlmService(private val preferencesManager: PreferencesManager) {

    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(60, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()

    suspend fun parseTextToWords(
        text: String,
        targetLanguage: String = ""
    ): Result<List<LlmParsedWord>> {
        val profile = preferencesManager.getActiveProfile()
        return parseWithProfile(text, targetLanguage, profile)
    }

    suspend fun parseFileToWords(
        content: String,
        targetLanguage: String = ""
    ): Result<List<LlmParsedWord>> {
        val profile = preferencesManager.getActiveProfile()
        return parseWithProfile(content, targetLanguage, profile)
    }

    private suspend fun parseWithProfile(
        text: String,
        targetLanguage: String,
        profile: LlmProfile
    ): Result<List<LlmParsedWord>> {
        return withContext(Dispatchers.IO) {
            try {
                if (profile.apiKey.isBlank()) {
                    return@withContext Result.failure(Exception("API key is not configured. Please set it in Settings."))
                }

                val includeExample = preferencesManager.includeExample.first()
                val includeCategory = preferencesManager.includeCategory.first()
                val includeNotes = preferencesManager.includeNotes.first()

                val langHint = if (targetLanguage.isNotBlank()) {
                    "Translate definitions to $targetLanguage. "
                } else {
                    "Translate definitions to Chinese. "
                }

                val exampleRequirement = if (includeExample) {
                    "Write example sentences in both English AND Chinese, format: \"English: xxx | Chinese: xxx\". "
                } else "Do NOT include example sentences. "

                val categoryRequirement = if (includeCategory) {
                    "Include a suitable category (e.g., Food, Travel, Business, Technology, Emotion, Academic, Daily Life). "
                } else "Set category to empty string. "

                val notesRequirement = if (includeNotes) {
                    "Include any additional notes about the word (usage tips, synonyms, common collocations). "
                } else "Set notes to empty string. "

                val systemPrompt = """
You are a professional vocabulary extraction assistant. Extract all meaningful vocabulary words and phrases from the provided text.

Rules:
- $langHint
- For each word provide: term, part_of_speech (noun/verb/adj/adv/prep/etc), definition
- If a word has multiple meanings for different parts of speech, include ALL in definition separated by "；" with POS labels. Example: "n. 苹果；v. 喜爱"
- $exampleRequirement
- $categoryRequirement
- $notesRequirement
- Return ONLY a valid JSON array with no markdown fences
- Format: [{"term": "...", "part_of_speech": "...", "definition": "...", "example_sentence": "...", "category": "..."}]
                """.trimIndent()

                val userPrompt = "Extract vocabulary from this text:\n\n$text"

                val requestBody = JSONObject().apply {
                    put("model", profile.model)
                    put("messages", JSONArray().apply {
                        put(JSONObject().apply { put("role", "system"); put("content", systemPrompt) })
                        put(JSONObject().apply { put("role", "user"); put("content", userPrompt) })
                    })
                    put("temperature", 0.3)
                    put("max_tokens", 4096)
                }

                val request = Request.Builder()
                    .url("${profile.baseUrl.trimEnd('/')}/v1/chat/completions")
                    .addHeader("Authorization", "Bearer ${profile.apiKey}")
                    .addHeader("Content-Type", "application/json")
                    .post(requestBody.toString().toRequestBody("application/json".toMediaType()))
                    .build()

                val response = client.newCall(request).execute()

                if (!response.isSuccessful) {
                    val errorBody = response.body?.string() ?: "Unknown error"
                    return@withContext Result.failure(Exception("API error ${response.code}: $errorBody"))
                }

                val responseBody = response.body?.string() ?: ""
                val json = JSONObject(responseBody)
                val choices = json.getJSONArray("choices")
                val content = choices.getJSONObject(0)
                    .getJSONObject("message")
                    .getString("content")

                val cleanedContent = content
                    .trim()
                    .removePrefix("```json")
                    .removePrefix("```")
                    .removeSuffix("```")
                    .trim()

                val wordsArray = JSONArray(cleanedContent)
                val words = mutableListOf<LlmParsedWord>()

                for (i in 0 until wordsArray.length()) {
                    val obj = wordsArray.getJSONObject(i)
                    words.add(
                        LlmParsedWord(
                            term = obj.optString("term", ""),
                            partOfSpeech = obj.optString("part_of_speech", ""),
                            definition = obj.optString("definition", ""),
                            exampleSentence = obj.optString("example_sentence", ""),
                            category = obj.optString("category", "")
                        )
                    )
                }

                Result.success(words)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }
}
