package com.example.vocabuilder

import android.app.Application
import android.content.res.Configuration
import com.example.vocabuilder.data.AppDatabase
import com.example.vocabuilder.data.PreferencesManager
import com.example.vocabuilder.data.repository.WordRepository
import com.example.vocabuilder.network.LlmService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import java.util.Locale

class VocabuilderApp : Application() {

    lateinit var database: AppDatabase
        private set
    lateinit var repository: WordRepository
        private set
    lateinit var preferencesManager: PreferencesManager
        private set
    lateinit var llmService: LlmService
        private set

    var currentLanguage: String = "auto"
        private set

    private val _languageFlow = MutableStateFlow("auto")
    val languageFlow: StateFlow<String> = _languageFlow.asStateFlow()

    private val appScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override fun onCreate() {
        super.onCreate()
        instance = this

        preferencesManager = PreferencesManager(this)
        database = AppDatabase.getInstance(this)
        repository = WordRepository(
            database.wordDao(),
            database.bookDao(),
            database.studyRecordDao()
        )
        llmService = LlmService(preferencesManager)

        currentLanguage = runBlocking { preferencesManager.language.first() }
        _languageFlow.value = currentLanguage

        appScope.launch {
            preferencesManager.language.collect { lang ->
                currentLanguage = lang
                _languageFlow.value = lang
            }
        }
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        applyLocale(newConfig)
    }

    fun applyLocale(config: Configuration) {
        if (currentLanguage == "auto") return
        val locale = languageToLocale(currentLanguage) ?: return
        Locale.setDefault(locale)
        config.setLocale(locale)
        @Suppress("DEPRECATION")
        resources.updateConfiguration(config, resources.displayMetrics)
    }

    companion object {
        lateinit var instance: VocabuilderApp
            private set

        fun languageToLocale(lang: String): Locale? = when (lang) {
            "zh" -> Locale.SIMPLIFIED_CHINESE
            "en" -> Locale.ENGLISH
            else -> null
        }
    }
}
