package com.example.vocabuilder.data.repository

import com.example.vocabuilder.data.dao.BookDao
import com.example.vocabuilder.data.dao.StudyRecordDao
import com.example.vocabuilder.data.dao.WordDao
import com.example.vocabuilder.data.entity.Book
import com.example.vocabuilder.data.entity.StudyRecord
import com.example.vocabuilder.data.entity.Word
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate
import java.time.format.DateTimeFormatter

class WordRepository(
    private val wordDao: WordDao,
    private val bookDao: BookDao,
    private val studyRecordDao: StudyRecordDao
) {

    fun getAllWords(): Flow<List<Word>> = wordDao.getAllWords()

    suspend fun getAllWordsOnce(): List<Word> = wordDao.getAllWordsOnce()

    fun getWordsByBookId(bookId: Long): Flow<List<Word>> = wordDao.getWordsByBookId(bookId)

    fun getWordsWithoutBook(): Flow<List<Word>> = wordDao.getWordsWithoutBook()

    fun getWordsByCategory(category: String): Flow<List<Word>> = wordDao.getWordsByCategory(category)

    fun getWordsDueForReview(currentTime: Long): Flow<List<Word>> = wordDao.getWordsDueForReview(currentTime)

    fun searchWords(query: String): Flow<List<Word>> = wordDao.searchWords(query)

    suspend fun getWordById(id: Long): Word? = wordDao.getWordById(id)

    suspend fun wordExists(term: String, bookId: Long?): Boolean = wordDao.getWordByTermAndBook(term, bookId) != null

    fun getAllCategories(): Flow<List<String>> = wordDao.getAllCategories()

    fun getTotalWordCount(): Flow<Int> = wordDao.getTotalWordCount()

    fun getLearnedWordCount(): Flow<Int> = wordDao.getLearnedWordCount()

    fun getLearnedWordCountForBook(bookId: Long): Flow<Int> = wordDao.getLearnedWordCountForBook(bookId)

    fun getDueWordCount(currentTime: Long): Flow<Int> = wordDao.getDueWordCount(currentTime)

    fun getWordCountForBook(bookId: Long): Flow<Int> = wordDao.getWordCountForBook(bookId)

    suspend fun insertWord(word: Word): Long = wordDao.insertWord(word)

    suspend fun insertWords(words: List<Word>): Unit = wordDao.insertWords(words)

    suspend fun updateWord(word: Word) = wordDao.updateWord(word)

    suspend fun deleteWord(word: Word) = wordDao.deleteWord(word)

    suspend fun deleteWordById(id: Long) = wordDao.deleteWordById(id)

    suspend fun assignWordsToBook(wordIds: List<Long>, bookId: Long?) = wordDao.assignWordsToBook(wordIds, bookId)

    fun getAllBooks(): Flow<List<Book>> = bookDao.getAllBooks()

    suspend fun getBookById(id: Long): Book? = bookDao.getBookById(id)

    suspend fun insertBook(book: Book): Long = bookDao.insertBook(book)

    suspend fun updateBook(book: Book) = bookDao.updateBook(book)

    suspend fun deleteBook(book: Book) = bookDao.deleteBook(book)

    suspend fun deleteBookById(id: Long) = bookDao.deleteBookById(id)

    suspend fun getWordsDueForReviewOnce(currentTime: Long): List<Word> = wordDao.getWordsDueForReviewOnce(currentTime)

    suspend fun getWordsDueForReviewOnceByBook(currentTime: Long, bookId: Long?): List<Word> =
        wordDao.getWordsDueForReviewOnceByBook(currentTime, bookId)

    suspend fun recordStudy(
        wordsReviewed: Int = 0,
        wordsLearned: Int = 0,
        wordsCorrect: Int = 0,
        quizScore: Int = 0,
        studyTimeMinutes: Int = 0
    ) {
        val today = LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE)
        val existing = studyRecordDao.getRecordByDate(today)
        if (existing != null) {
            studyRecordDao.updateRecord(
                existing.copy(
                    wordsReviewed = existing.wordsReviewed + wordsReviewed,
                    wordsLearned = existing.wordsLearned + wordsLearned,
                    wordsCorrect = existing.wordsCorrect + wordsCorrect,
                    quizScore = existing.quizScore.coerceAtLeast(quizScore),
                    studyTimeMinutes = existing.studyTimeMinutes + studyTimeMinutes
                )
            )
        } else {
            studyRecordDao.insertRecord(
                StudyRecord(
                    date = today,
                    wordsReviewed = wordsReviewed,
                    wordsLearned = wordsLearned,
                    wordsCorrect = wordsCorrect,
                    quizScore = quizScore,
                    studyTimeMinutes = studyTimeMinutes
                )
            )
        }
    }

    fun getLast7DaysRecords(): Flow<List<StudyRecord>> = studyRecordDao.getLast7DaysRecords()

    fun getTotalWordsReviewed(): Flow<Int> = studyRecordDao.getTotalWordsReviewed()

    fun getTotalWordsLearned(): Flow<Int> = studyRecordDao.getTotalWordsLearned()

    fun getTotalStudyTime(): Flow<Int> = studyRecordDao.getTotalStudyTime()

    suspend fun deleteStudyRecord(record: StudyRecord) { studyRecordDao.deleteRecord(record) }
}
