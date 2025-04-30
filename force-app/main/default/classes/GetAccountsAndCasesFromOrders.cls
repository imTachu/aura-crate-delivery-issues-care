public with sharing class GetAccountsAndCasesFromOrders {
    public class Input {
        @InvocableVariable(required=true)
        public List<String> orderIds;
    }
    public class CaseOutput {
        @InvocableVariable
        public Id caseId;

        @InvocableVariable
        public String subject;
        
        @InvocableVariable
        public DateTime createdDate;
        
        @InvocableVariable
        public String origin;
    }

    public class AccountOutput {
        @InvocableVariable
        public Id accountId;

        @InvocableVariable
        public String accountName;

        @InvocableVariable
        public List<CaseOutput> cases;
    }

    @InvocableMethod(label='Get Accounts and Cases from Order Numbers')
    public static List<AccountOutput> fetchAccountsAndCases(List<Input> inputs) {
        Set<String> orderNumbers = new Set<String>();
        for (Input input : inputs) {
            if (input.orderIds != null) {
                for (String order : input.orderIds) {
                    if (!String.isBlank(order)) {
                        orderNumbers.add(order.trim());
                    }
                }
            }
        }

        if (orderNumbers.isEmpty())
            return new List<AccountOutput>();

        List<Order> orders = [
            SELECT Id, AccountId, OrderNumber
            FROM Order
            WHERE OrderNumber IN :orderNumbers AND AccountId != NULL
        ];

        Set<Id> accountIds = new Set<Id>();
        for (Order o : orders) {
            accountIds.add(o.AccountId);
        }

        if (accountIds.isEmpty())
            return new List<AccountOutput>();

        Map<Id, Account> accounts = new Map<Id, Account>(
            [
                SELECT Id, Name
                FROM Account
                WHERE Id IN :accountIds
            ]
        );

        Map<Id, List<CaseOutput>> accountToCases = new Map<Id, List<CaseOutput>>();
        for (Case c : [
            SELECT Id, Subject, CreatedDate, Origin, AccountId
            FROM Case
            WHERE AccountId IN :accountIds AND CreatedDate = LAST_N_DAYS:365
        ]) {
            if (!accountToCases.containsKey(c.AccountId)) {
                accountToCases.put(c.AccountId, new List<CaseOutput>());
            }
            CaseOutput co = new CaseOutput();
            co.caseId = c.Id;
            co.subject = c.Subject;
            co.createdDate = c.CreatedDate;
            co.origin = c.Origin;
            accountToCases.get(c.AccountId).add(co);
        }

        List<AccountOutput> results = new List<AccountOutput>();
        for (Id accId : accountIds) {
            AccountOutput ao = new AccountOutput();
            ao.accountId = accId;
            ao.accountName = accounts.get(accId).Name;
            ao.cases = accountToCases.containsKey(accId)
                ? accountToCases.get(accId)
                : new List<CaseOutput>();
            results.add(ao);
        }
        return results;
    }
}
