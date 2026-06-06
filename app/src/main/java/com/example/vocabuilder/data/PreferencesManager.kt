package com.example.vocabuilder.data

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.example.vocabuilder.data.entity.LlmProfile
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import org.json.JSONArray
import org.json.JSONObject

val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "vocabuilder_settings")

class PreferencesManager(private val context: Context) {

    companion object {
        val LANGUAGE_KEY = stringPreferencesKey("app_language")
        val THEME_MODE_KEY = stringPreferencesKey("theme_mode")
        val LLM_PROFILES_KEY = stringPreferencesKey("llm_profiles_json")
        val ACTIVE_PROFILE_ID_KEY = stringPreferencesKey("active_profile_id")
        val INCLUDE_EXAMPLE_KEY = booleanPreferencesKey("include_example")
        val INCLUDE_CATEGORY_KEY = booleanPreferencesKey("include_category")
        val INCLUDE_NOTES_KEY = booleanPreferencesKey("include_notes")
        val TARGET_LANGUAGE_KEY = stringPreferencesKey("target_language")
    }

    val language: Flow<String> = context.dataStore.data.map { prefs ->
        prefs[LANGUAGE_KEY] ?: "auto"
    }

    val themeMode: Flow<String> = context.dataStore.data.map { prefs ->
        prefs[THEME_MODE_KEY] ?: "system"
    }

    val llmProfiles: Flow<List<LlmProfile>> = context.dataStore.data.map { prefs ->
        val json = prefs[LLM_PROFILES_KEY]
        if (json.isNullOrBlank()) {
            listOf(LlmProfile(name = "Default"))
        } else {
            try {
                val arr = JSONArray(json)
                (0 until arr.length()).map { i ->
                    val obj = arr.getJSONObject(i)
                    LlmProfile(
                        id = obj.optString("id", java.util.UUID.randomUUID().toString()),
                        name = obj.optString("name", "Default"),
                        baseUrl = obj.optString("baseUrl", "https://api.openai.com"),
                        apiKey = obj.optString("apiKey", ""),
                        model = obj.optString("model", "gpt-4o-mini")
                    )
                }
            } catch (e: Exception) {
                listOf(LlmProfile(name = "Default"))
            }
        }
    }

    val activeProfileId: Flow<String?> = context.dataStore.data.map { prefs ->
        prefs[ACTIVE_PROFILE_ID_KEY]
    }

    val includeExample: Flow<Boolean> = context.dataStore.data.map { prefs -> prefs[INCLUDE_EXAMPLE_KEY] ?: true }
    val includeCategory: Flow<Boolean> = context.dataStore.data.map { prefs -> prefs[INCLUDE_CATEGORY_KEY] ?: false }
    val includeNotes: Flow<Boolean> = context.dataStore.data.map { prefs -> prefs[INCLUDE_NOTES_KEY] ?: false }
    val targetLanguage: Flow<String> = context.dataStore.data.map { prefs -> prefs[TARGET_LANGUAGE_KEY] ?: "Chinese (中文)" }

    suspend fun setLanguage(lang: String) {
        context.dataStore.edit { prefs -> prefs[LANGUAGE_KEY] = lang }
    }

    suspend fun setThemeMode(mode: String) {
        context.dataStore.edit { prefs -> prefs[THEME_MODE_KEY] = mode }
    }

    suspend fun saveProfile(profile: LlmProfile) {
        val currentProfiles = getCurrentProfiles().toMutableList()
        val idx = currentProfiles.indexOfFirst { it.id == profile.id }
        if (idx >= 0) currentProfiles[idx] = profile
        else currentProfiles.add(profile)
        writeProfiles(currentProfiles)
    }

    suspend fun deleteProfile(profileId: String) {
        val profiles = getCurrentProfiles().filter { it.id != profileId }
        if (profiles.isEmpty()) {
            writeProfiles(listOf(LlmProfile(name = "Default")))
        } else {
            writeProfiles(profiles)
        }
    }

    suspend fun setActiveProfile(profileId: String?) {
        context.dataStore.edit { prefs -> prefs[ACTIVE_PROFILE_ID_KEY] = profileId ?: "" }
    }

    suspend fun setIncludeExample(value: Boolean) { context.dataStore.edit { prefs -> prefs[INCLUDE_EXAMPLE_KEY] = value } }
    suspend fun setIncludeCategory(value: Boolean) { context.dataStore.edit { prefs -> prefs[INCLUDE_CATEGORY_KEY] = value } }
    suspend fun setIncludeNotes(value: Boolean) { context.dataStore.edit { prefs -> prefs[INCLUDE_NOTES_KEY] = value } }
    suspend fun setTargetLanguage(lang: String) { context.dataStore.edit { prefs -> prefs[TARGET_LANGUAGE_KEY] = lang } }

    suspend fun getActiveProfile(): LlmProfile {
        val profiles = llmProfiles.first()
        val activeId = activeProfileId.first()
        return profiles.find { it.id == activeId } ?: profiles.firstOrNull() ?: LlmProfile()
    }

    private suspend fun getCurrentProfiles(): List<LlmProfile> {
        val prefs = context.dataStore.data.first()
        val json = prefs[LLM_PROFILES_KEY]
        if (json.isNullOrBlank()) return listOf(LlmProfile(name = "Default"))
        return try {
            val arr = JSONArray(json)
            (0 until arr.length()).map { i ->
                val obj = arr.getJSONObject(i)
                LlmProfile(
                    id = obj.optString("id"),
                    name = obj.optString("name"),
                    baseUrl = obj.optString("baseUrl"),
                    apiKey = obj.optString("apiKey"),
                    model = obj.optString("model")
                )
            }
        } catch (e: Exception) {
            listOf(LlmProfile(name = "Default"))
        }
    }

    private suspend fun writeProfiles(profiles: List<LlmProfile>) {
        val arr = JSONArray()
        profiles.forEach { p ->
            arr.put(JSONObject().apply {
                put("id", p.id)
                put("name", p.name)
                put("baseUrl", p.baseUrl)
                put("apiKey", p.apiKey)
                put("model", p.model)
            })
        }
        context.dataStore.edit { prefs -> prefs[LLM_PROFILES_KEY] = arr.toString() }
    }
}
