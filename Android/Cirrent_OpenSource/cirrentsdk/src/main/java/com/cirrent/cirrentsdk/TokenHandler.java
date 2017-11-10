package com.cirrent.cirrentsdk;


public interface TokenHandler {
    public enum TOKEN_TYPE {
        SEARCH,
        BIND,
        MANAGE,
        ANY
    };

    public interface GetTokenCompletionHandler {
        public void getTokenCompleted(final String token);
    }

    public void getToken(TOKEN_TYPE tokenType, String deviceID, GetTokenCompletionHandler completionHandler);
}
