public with sharing class CreateIncidentFromImpactedOrders {
    public class Input {
        @InvocableVariable(required=true)
        public String subject;

        @InvocableVariable(required=true)
        public String description;

        @InvocableVariable(required=true)
        public String urgency;
        
        @InvocableVariable(required=true)
        public String impact;
        
        @InvocableVariable(required=true)
        public String priority;
        
        @InvocableVariable(required=true)
        public String churnRisk;
        
        @InvocableVariable(required=true)
        public String preferredCommunicationMethod;
        
        @InvocableVariable(required=true)
        public String bestCommunicationTone;
        
        @InvocableVariable(required=true)
        public String suggestedCompensation;
        
        @InvocableVariable(required=true)
        public DateTime startDateTime;
        
        @InvocableVariable
        public List<String> orderIds;
    }

    public class Output {
        @InvocableVariable
        public Id incidentId;
    }

    @InvocableMethod(label='Create Incident and Related Items')
    public static List<Output> createIncidentAndRelatedItems(List<Input> inputs) {
        if (inputs.isEmpty())
            return new List<Output>();

        Input input = inputs[0];

        Incident inc = new Incident();
        inc.Subject = input.subject;
        inc.Description = input.description;
        inc.Urgency = input.urgency;
        inc.Impact = input.impact;
        inc.Priority = input.priority;
        inc.StartDateTime = input.startDateTime;

        insert inc;

        if (input.orderIds != null && !input.orderIds.isEmpty()) {
            List<Order> orders = [
                SELECT Id, AccountId
                FROM Order
                WHERE OrderNumber IN :input.orderIds
            ];

            List<IncidentRelatedItem> relatedItems = new List<IncidentRelatedItem>();
            for (Order o : orders) {
                IncidentRelatedItem iri = new IncidentRelatedItem();
                iri.IncidentId = inc.Id;
                iri.Order__c = o.Id;
                iri.Account__c = o.AccountId;
                iri.Churn_Risk__c = input.churnRisk;
                iri.Preferred_Communication_Channel__c = input.preferredCommunicationMethod;
                iri.Suggested_Communication_Tone__c = input.bestCommunicationTone;
                iri.Suggested_Compensation__c = input.suggestedCompensation;
                // default, won't be used but it's required
                iri.Product2Id = '01tKB0000018KYIYA2';
                relatedItems.add(iri);
            }

            if (!relatedItems.isEmpty()) {
                insert relatedItems;
            }
        }

        Output out = new Output();
        out.incidentId = inc.Id;
        return new List<Output>{ out };
    }
}
