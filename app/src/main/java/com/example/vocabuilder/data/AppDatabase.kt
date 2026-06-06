package com.example.vocabuilder.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import com.example.vocabuilder.data.dao.BookDao
import com.example.vocabuilder.data.dao.StudyRecordDao
import com.example.vocabuilder.data.dao.WordDao
import com.example.vocabuilder.data.entity.Book
import com.example.vocabuilder.data.entity.StudyRecord
import com.example.vocabuilder.data.entity.Word

@Database(
    entities = [Word::class, Book::class, StudyRecord::class],
    version = 2,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {

    abstract fun wordDao(): WordDao
    abstract fun bookDao(): BookDao
    abstract fun studyRecordDao(): StudyRecordDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getInstance(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "vocabuilder_database"
                )
                    .fallbackToDestructiveMigration()
                    .build()
                    .also { INSTANCE = it }
            }
        }
    }
}
