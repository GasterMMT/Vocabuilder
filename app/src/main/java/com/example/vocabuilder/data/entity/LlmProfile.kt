package com.example.vocabuilder.data.entity

data class LlmProfile(
    val id: String = java.util.UUID.randomUUID().toString(),
    val name: String = "Default",
    val baseUrl: String = "https://api.openai.com",
    val apiKey: String = "",
    val model: String = "gpt-4o-mini"
)
