package ru.aleshi.letsplaycities.social

/**
 * Describes available social authorization services
 */
enum class ServiceType(val socialNetworkName: String) {
    Vkontakte("vk"), Odnoklassniki("ok"), Facebook("fb");

    companion object {
        @JvmStatic
        fun fromString(name: String): ServiceType {
            for (type in values()) {
                if (type.socialNetworkName == name) return type
            }
            throw IllegalArgumentException("Invalid service name: $name")
        }
    }
}