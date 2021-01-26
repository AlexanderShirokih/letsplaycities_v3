package ru.aleshi.letsplaycities.social

/**
 * Standard error code used when user cancels authorization process
 */
const val CANCELLED_BY_USER = 2

/**
 * Standard error code used when authorization process was failed
 */
const val AUTH_FAILED = 1

/**
 * Signals the authorization error
 */
class AuthorizationException(
        val errorCode: Int,
        val description: String = "Authorization failed"
) : Exception()