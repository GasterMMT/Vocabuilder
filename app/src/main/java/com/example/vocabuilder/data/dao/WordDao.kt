package com.example.vocabuilder.data.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.example.vocabuilder.data.entity.Word
import kotlinx.coroutines.flow.Flow

@Dao
interface WordDao {

    @Query("SELECT * FROM words ORDER BY updatedAt DESC")
    fun getAllWords(): Flow<List<Word>>

    @Query("SELECT * FROM words ORDER BY updatedAt DESC")
    suspend fun getAllWordsOnce(): List<Word>

    @Query("SELECT * FROM words WHERE bookId = :bookId ORDER BY updatedAt DESC")
    fun getWordsByBookId(bookId: Long): Flow<List<Word>>

    @Query("SELECT * FROM words WHERE bookId IS NULL ORDER BY updatedAt DESC")
    fun getWordsWithoutBook(): Flow<List<Word>>

    @Query("SELECT * FROM words WHERE category = :category ORDER BY updatedAt DESC")
    fun getWordsByCategory(category: String): Flow<List<Word>>

    @Query("SELECT * FROM words WHERE nextReviewDate <= :currentTime ORDER BY nextReviewDate ASC")
    fun getWordsDueForReview(currentTime: Long): Flow<List<Word>>

    @Query("SELECT * FROM words WHERE nextReviewDate <= :currentTime ORDER BY nextReviewDate ASC")
    suspend fun getWordsDueForReviewOnce(currentTime: Long): List<Word>

    @Query("SELECT * FROM words WHERE nextReviewDate <= :currentTime AND (:bookId IS NULL OR bookId = :bookId) ORDER BY nextReviewDate ASC")
    suspend fun getWordsDueForReviewOnceByBook(currentTime: Long, bookId: Long?): List<Word>

    @Query("SELECT * FROM words WHERE term LIKE '%' || :query || '%' OR definition LIKE '%' || :query || '%' ORDER BY updatedAt DESC")
    fun searchWords(query: String): Flow<List<Word>>

    @Query("SELECT * FROM words WHERE id = :id")
    suspend fun getWordById(id: Long): Word?

    @Query("SELECT * FROM words WHERE term = :term AND (bookId = :bookId OR (:bookId IS NULL AND bookId IS NULL)) LIMIT 1")
    suspend fun getWordByTermAndBook(term: String, bookId: Long?): Word?

    @Query("SELECT DISTINCT category FROM words WHERE category != ''")
    fun getAllCategories(): Flow<List<String>>

    @Query("SELECT COUNT(*) FROM words")
    fun getTotalWordCount(): Flow<Int>

    @Query("SELECT COUNT(*) FROM words WHERE consecutiveCorrect >= 3")
    fun getLearnedWordCount(): Flow<Int>

    @Query("SELECT COUNT(*) FROM words WHERE bookId = :bookId AND consecutiveCorrect >= 3")
    fun getLearnedWordCountForBook(bookId: Long): Flow<Int>

    @Query("SELECT COUNT(*) FROM words WHERE nextReviewDate <= :currentTime")
    fun getDueWordCount(currentTime: Long): Flow<Int>

    @Query("SELECT COUNT(*) FROM words WHERE bookId = :bookId")
    fun getWordCountForBook(bookId: Long): Flow<Int>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertWord(word: Word): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertWords(words: List<Word>)

    @Update
    suspend fun updateWord(word: Word)

    @Delete
    suspend fun deleteWord(word: Word)

    @Query("DELETE FROM words WHERE id = :id")
    suspend fun deleteWordById(id: Long)

    @Query("UPDATE words SET bookId = :bookId WHERE id IN (:wordIds)")
    suspend fun assignWordsToBook(wordIds: List<Long>, bookId: Long?)
}
