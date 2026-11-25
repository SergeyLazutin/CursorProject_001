@IsTest
private class AccountHealthServiceTest {
    @IsTest
    static void updateHealthScores_setsRepresentativeCompositeScores() {
        List<Account> accounts = new List<Account>{
            new Account(
                Name = 'Max Health',
                AnnualRevenue = 1000000,
                Last_90_Day_Wins__c = 100000
            ),
            new Account(
                Name = 'Mid Health',
                AnnualRevenue = 500000,
                Last_90_Day_Wins__c = 10000
            ),
            new Account(
                Name = 'Low Health',
                AnnualRevenue = 100000,
                Last_90_Day_Wins__c = 0
            ),
            new Account(
                Name = 'No Health',
                AnnualRevenue = null,
                Last_90_Day_Wins__c = null
            )
        };
        insert accounts;

        Set<Id> accountIds = new Map<Id, Account>(accounts).keySet();

        Test.startTest();
        AccountHealthService.updateHealthScores(accountIds);
        Test.stopTest();

        Map<String, Account> accountsByName = new Map<String, Account>();
        for (Account acct : [
            SELECT Name, Health_Score__c
            FROM Account
            WHERE Id IN :accountIds
        ]) {
            accountsByName.put(acct.Name, acct);
        }

        System.assertEquals(
            100,
            accountsByName.get('Max Health').Health_Score__c,
            'Top revenue (50) + top wins (50) should equal 100'
        );
        System.assertEquals(
            40,
            accountsByName.get('Mid Health').Health_Score__c,
            'Mid revenue (30) + low wins (10) should equal 40'
        );
        System.assertEquals(
            10,
            accountsByName.get('Low Health').Health_Score__c,
            'Low revenue (10) + no wins (0) should equal 10'
        );
        System.assertEquals(
            0,
            accountsByName.get('No Health').Health_Score__c,
            'No revenue (0) + no wins (0) should equal 0'
        );
    }

    @IsTest
    static void updateHealthScores_noOpWhenAccountIdsNullOrEmpty() {
        Test.startTest();
        AccountHealthService.updateHealthScores(null);
        AccountHealthService.updateHealthScores(new Set<Id>());
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Account],
            'Guard clauses should not create or update any account data'
        );
    }

    @IsTest
    static void updateHealthScores_evaluatesBucketBoundaries() {
        List<Account> accounts = new List<Account>{
            new Account(
                Name = 'Revenue Tier 2 Boundary',
                AnnualRevenue = 250000,
                Last_90_Day_Wins__c = 0
            ),
            new Account(
                Name = 'Revenue Tier 3 Boundary',
                AnnualRevenue = 1000000,
                Last_90_Day_Wins__c = 0
            ),
            new Account(
                Name = 'Wins Tier 2 Boundary',
                AnnualRevenue = 0,
                Last_90_Day_Wins__c = 25000
            ),
            new Account(
                Name = 'Wins Tier 3 Boundary',
                AnnualRevenue = 0,
                Last_90_Day_Wins__c = 100000
            )
        };
        insert accounts;

        Set<Id> accountIds = new Map<Id, Account>(accounts).keySet();

        Test.startTest();
        AccountHealthService.updateHealthScores(accountIds);
        Test.stopTest();

        Map<String, Account> accountsByName = new Map<String, Account>();
        for (Account acct : [
            SELECT Name, Health_Score__c
            FROM Account
            WHERE Id IN :accountIds
        ]) {
            accountsByName.put(acct.Name, acct);
        }

        System.assertEquals(30, accountsByName.get('Revenue Tier 2 Boundary').Health_Score__c);
        System.assertEquals(50, accountsByName.get('Revenue Tier 3 Boundary').Health_Score__c);
        System.assertEquals(30, accountsByName.get('Wins Tier 2 Boundary').Health_Score__c);
        System.assertEquals(50, accountsByName.get('Wins Tier 3 Boundary').Health_Score__c);
    }
}
