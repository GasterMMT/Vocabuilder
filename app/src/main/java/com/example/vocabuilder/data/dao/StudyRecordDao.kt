package com.example.vocabuilder.data.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.example.vocabuilder.data.entity.StudyRecord
import kotlinx.coroutines.flow.Flow

@Dao
interface StudyRecordDao {

    @Query("SELECT * FROM study_records ORDER BY date DESC")
    fun getAllRecords(): Flow<List<StudyRecord>>

    @Query("SELECT * FROM study_records WHERE date = :date LIMIT 1")
    suspend fun getRecordByDate(date: String): StudyRecord?

    @Query("SELECT COALESCE(SUM(wordsReviewed), 0) FROM study_records")
    fun getTotalWordsReviewed(): Flow<Int>

    @Query("SELECT COALESCE(SUM(wordsLearned), 0) FROM study_records")
    fun getTotalWordsLearned(): Flow<Int>

    @Query("SELECT COALESCE(SUM(studyTimeMinutes), 0) FROM study_records")
    fun getTotalStudyTime(): Flow<Int>

    @Query("SELECT * FROM study_records ORDER BY date DESC LIMIT 7")
    fun getLast7DaysRecords(): Flow<List<StudyRecord>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertRecord(record: StudyRecord)

    @Update
    suspend fun updateRecord(record: StudyRecord)

    @Delete
    suspend fun deleteRecord(record: StudyRecord)
}
