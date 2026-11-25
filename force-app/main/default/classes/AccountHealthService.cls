public with sharing class AccountHealthService {
    private static final Decimal REVENUE_TIER_2 = 250000;
    private static final Decimal REVENUE_TIER_3 = 1000000;
    private static final Decimal WINS_TIER_2 = 25000;
    private static final Decimal WINS_TIER_3 = 100000;

    public static void updateHealthScores(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }

        List<Account> accounts = [
            SELECT Id, AnnualRevenue, Last_90_Day_Wins__c, Health_Score__c
            FROM Account
            WHERE Id IN :accountIds
        ];

        for (Account acct : accounts) {
            Integer revenueScore = calculateRevenueScore(acct.AnnualRevenue);
            Integer recentWinsScore = calculateRecentWinsScore(acct.Last_90_Day_Wins__c);
            acct.Health_Score__c = revenueScore + recentWinsScore;
        }

        if (!accounts.isEmpty()) {
            update accounts;
        }
    }

    private static Integer calculateRevenueScore(Decimal annualRevenue) {
        if (annualRevenue == null || annualRevenue == 0) {
            return 0;
        }
        if (annualRevenue > 0 && annualRevenue < REVENUE_TIER_2) {
            return 10;
        }
        if (annualRevenue >= REVENUE_TIER_2 && annualRevenue < REVENUE_TIER_3) {
            return 30;
        }
        if (annualRevenue >= REVENUE_TIER_3) {
            return 50;
        }
        return 0;
    }

    private static Integer calculateRecentWinsScore(Decimal last90DayWins) {
        if (last90DayWins == null || last90DayWins == 0) {
            return 0;
        }
        if (last90DayWins > 0 && last90DayWins < WINS_TIER_2) {
            return 10;
        }
        if (last90DayWins >= WINS_TIER_2 && last90DayWins < WINS_TIER_3) {
            return 30;
        }
        if (last90DayWins >= WINS_TIER_3) {
            return 50;
        }
        return 0;
    }
}
