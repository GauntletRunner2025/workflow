using UnityEngine;

namespace GauntletRunner.Workflow
{
    /// <summary>
    /// Utility class for accessing API keys stored in EditorPrefs.
    /// </summary>
    public static class APIKeyManager
    {
        /// <summary>
        /// Gets an API key stored in EditorPrefs.
        /// </summary>
        /// <param name="keyName">The name of the API key to retrieve.</param>
        /// <returns>The API key value, or an empty string if not found.</returns>
        public static string GetAPIKey(string keyName)
        {
#if UNITY_EDITOR
            return UnityEditor.EditorPrefs.GetString(keyName, "");
#else
            Debug.LogWarning("API keys stored in EditorPrefs are not available at runtime in builds. Consider using a secure runtime storage solution for production.");
            return "";
#endif
        }

        /// <summary>
        /// Checks if an API key exists in EditorPrefs.
        /// </summary>
        /// <param name="keyName">The name of the API key to check.</param>
        /// <returns>True if the key exists, false otherwise.</returns>
        public static bool HasAPIKey(string keyName)
        {
#if UNITY_EDITOR
            return UnityEditor.EditorPrefs.HasKey(keyName);
#else
            Debug.LogWarning("API keys stored in EditorPrefs are not available at runtime in builds. Consider using a secure runtime storage solution for production.");
            return false;
#endif
        }

        /// <summary>
        /// Prompts the user to enter an API key if it doesn't exist.
        /// This method should only be called from editor scripts.
        /// </summary>
        /// <param name="keyName">The name of the API key to check/request.</param>
        /// <returns>True if the key exists or was successfully entered, false otherwise.</returns>
        public static bool EnsureAPIKeyExists(string keyName)
        {
#if UNITY_EDITOR
            if (HasAPIKey(keyName))
                return true;

            // Open the API Key Manager window
            UnityEditor.EditorApplication.ExecuteMenuItem("Tools/API Key Manager");
            
            // Show a message to guide the user
            UnityEditor.EditorUtility.DisplayDialog(
                "API Key Required", 
                $"Please enter your '{keyName}' API key in the API Key Manager window that just opened.", 
                "OK");
            
            return false;
#else
            Debug.LogWarning("API keys stored in EditorPrefs are not available at runtime in builds.");
            return false;
#endif
        }
    }
} 