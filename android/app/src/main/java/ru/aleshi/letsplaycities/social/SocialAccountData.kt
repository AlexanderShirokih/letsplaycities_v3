package ru.aleshi.letsplaycities.social

/**
 * Data class for keeping account data from authorized social network
 */
class SocialAccountData(
        /**
         * Social network ID
         */
        val snUID: String,
        /**
         * User login
         */
        val login: String,
        /**
         * OAuth access_token
         */
        val accessToken: String,
        /**
         * Social network provider type
         */
        val networkType: ServiceType,
        /**
         * Avatar URL
         */
        val pictureUri: String,
) {

    /**
     * Converts representation of this object to Map
     */
    fun encodeToMap(): Map<String, Any> =
            mapOf(
                    "snUID" to snUID,
                    "login" to login,
                    "accessToken" to accessToken,
                    "networkType" to networkType.socialNetworkName,
                    "pictureUri" to pictureUri,
            )

}