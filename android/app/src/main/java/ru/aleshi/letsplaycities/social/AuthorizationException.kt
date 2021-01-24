package ru.aleshi.letsplaycities.social

/**
 * Signals the authorization error
 */
class AuthorizationException(
        val errorCode: Int,
        val description: String = "Authorization failed"
) : Exception()