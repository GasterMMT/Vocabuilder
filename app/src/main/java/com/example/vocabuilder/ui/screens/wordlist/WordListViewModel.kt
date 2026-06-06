package com.example.vocabuilder.ui.screens.wordlist

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.vocabuilder.VocabuilderApp
import com.example.vocabuilder.data.entity.Book
import com.example.vocabuilder.data.entity.LlmProfile
import com.example.vocabuilder.data.entity.Word
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class WordListViewModel : ViewModel() {

    private val repository = VocabuilderApp.instance.repository
    private val preferencesManager = VocabuilderApp.instance.preferencesManager

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    private val _selectedCategories = MutableStateFlow<Set<String>>(emptySet())
    val selectedCategories: StateFlow<Set<String>> = _selectedCategories.asStateFlow()

    private val _selectedBookId = MutableStateFlow<Long?>(null)
    val selectedBookId: StateFlow<Long?> = _selectedBookId.asStateFlow()

    private val _refreshTrigger = MutableStateFlow(0L)

    private val _selectedWordIds = MutableStateFlow<Set<Long>>(emptySet())
    val selectedWordIds: StateFlow<Set<Long>> = _selectedWordIds.asStateFlow()

    private val _isSelectionMode = MutableStateFlow(false)
    val isSelectionMode: StateFlow<Boolean> = _isSelectionMode.asStateFlow()

    private val _sortMode = MutableStateFlow(0)
    val sortMode: StateFlow<Int> = _sortMode.asStateFlow()

    val books: StateFlow<List<Book>> = repository.getAllBooks()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val llmProfiles: StateFlow<List<LlmProfile>> = preferencesManager.llmProfiles
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), listOf(LlmProfile(name = "Default")))

    val activeProfileId: StateFlow<String?> = preferencesManager.activeProfileId
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    @OptIn(ExperimentalCoroutinesApi::class)
    val words: StateFlow<List<Word>> = combine(_searchQuery, _selectedBookId, _refreshTrigger, _sortMode) { query, bookId, _, sortM -> Triple(query, bookId, sortM) }
        .flatMapLatest { (query, bookId, sortM) ->
            val rawFlow = if (query.isBlank()) when (bookId) { null -> repository.getAllWords(); else -> repository.getWordsByBookId(bookId) }
            else repository.searchWords(query)
            rawFlow.map { list ->
                when (sortM) {
                    0 -> list.sortedBy { it.term.lowercase() }
                    1 -> list.sortedByDescending { it.term.lowercase() }
                    else -> list.sortedByDescending { it.createdAt }
                }
            }
        }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val categories: StateFlow<List<String>> = repository.getAllCategories()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val totalWordCount: StateFlow<Int> = repository.getTotalWordCount()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0)

    val dueWordCount: StateFlow<Int> = repository.getDueWordCount(System.currentTimeMillis())
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0)

    fun onSearchQueryChanged(query: String) { _searchQuery.value = query }
    fun onCategoryToggled(category: String) {
        val current = _selectedCategories.value.toMutableSet()
        if (current.contains(category)) current.remove(category) else current.add(category)
        _selectedCategories.value = current
    }
    fun onBookSelected(bookId: Long?) { _selectedBookId.value = bookId; _refreshTrigger.value++ }
    fun deleteWord(word: Word) { viewModelScope.launch { repository.deleteWord(word) } }
    fun removeWordFromBook(word: Word) {
        viewModelScope.launch {
            repository.updateWord(word.copy(bookId = null))
            _refreshTrigger.value++
        }
    }

    suspend fun getWordsForExport(bookId: Long?): List<Word> {
        val flow = if (bookId != null) repository.getWordsByBookId(bookId) else repository.getAllWords()
        return flow.first()
    }

    fun importWordsFromJson(jsonContent: String, bookId: Long?) {
        viewModelScope.launch {
            try {
                val json = org.json.JSONObject(jsonContent)
                val wordsArr = json.getJSONArray("words")
                val bookName = json.optString("bookName", "")

                // Auto-create book from JSON metadata if importing to no book
                var targetBookId = bookId
                if (targetBookId == null && bookName.isNotBlank()) {
                    val allBooks = repository.getAllBooks()
                    val firstBooks = allBooks.first()
                    val existingBook = firstBooks.find { it.name == bookName }
                    targetBookId = if (existingBook != null) existingBook.id else repository.insertBook(Book(name = bookName))
                    _selectedBookId.value = targetBookId
                }

                val words = mutableListOf<Word>()
                for (i in 0 until wordsArr.length()) {
                    val obj = wordsArr.getJSONObject(i)
                    val term = obj.optString("term")
                    if (repository.wordExists(term, targetBookId)) continue
                    words.add(Word(term = term, definition = obj.optString("definition"), exampleSentence = obj.optString("exampleSentence", ""), category = obj.optString("category", ""), notes = obj.optString("notes", ""), bookId = targetBookId))
                }
                if (words.isNotEmpty()) repository.insertWords(words)
                _refreshTrigger.value++
            } catch (_: Exception) { }
        }
    }

    // Book management
    fun createBook(name: String) {
        viewModelScope.launch { repository.insertBook(Book(name = name.trim())) }
    }
    fun deleteBook(book: Book) {
        viewModelScope.launch {
            repository.deleteBook(book)
            if (_selectedBookId.value == book.id) _selectedBookId.value = null
            _refreshTrigger.value++
        }
    }

    // LLM Profile management
    fun saveProfile(profile: LlmProfile) {
        viewModelScope.launch { preferencesManager.saveProfile(profile) }
    }
    fun deleteLlmProfile(profile: LlmProfile) {
        viewModelScope.launch { preferencesManager.deleteProfile(profile.id) }
    }
    fun setActiveProfile(id: String?) {
        viewModelScope.launch { preferencesManager.setActiveProfile(id) }
    }

    // Multi-select
    fun toggleWordSelection(wordId: Long) {
        val current = _selectedWordIds.value.toMutableSet()
        if (current.contains(wordId)) current.remove(wordId) else current.add(wordId)
        _selectedWordIds.value = current
        _isSelectionMode.value = current.isNotEmpty()
    }

    fun clearSelection() {
        _selectedWordIds.value = emptySet()
        _isSelectionMode.value = false
    }

    fun selectAllVisible() {
        _selectedWordIds.value = words.value.map { it.id }.toSet()
        _isSelectionMode.value = _selectedWordIds.value.isNotEmpty()
    }

    fun toggleSort() { setSortMode((_sortMode.value + 1) % 3) }
    fun setSortMode(mode: Int) { _sortMode.value = mode }

    fun moveSelectedToBook(bookId: Long?) {
        viewModelScope.launch {
            repository.assignWordsToBook(_selectedWordIds.value.toList(), bookId)
            clearSelection()
            _refreshTrigger.value++
        }
    }

    fun deleteSelected(currentBookId: Long?) {
        viewModelScope.launch {
            if (currentBookId != null) {
                repository.assignWordsToBook(_selectedWordIds.value.toList(), null)
            } else {
                _selectedWordIds.value.forEach { repository.deleteWordById(it) }
            }
            clearSelection()
            _refreshTrigger.value++
        }
    }

    companion object {
        val Factory: ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T = WordListViewModel() as T
        }
    }
}
