public with sharing class IncidentAssistantAgentOrchestration {
    private final static String STANDARD_AI_ACTION = 'generateAiAgentResponse';
    private final static String AGENT_NAME = 'Agentforce_Service_Agent';

    public class Input {
        @InvocableVariable(required=true)
        public List<String> orderIds;
    }

    public class OrderResult {
        @InvocableVariable
        public String orderId;

        @InvocableVariable
        public String analysisOutput;
    }

    @InvocableMethod(label='Invoke Incident Assistant Agent per Order')
    public static List<OrderResult> runAnalysis(List<Input> inputs) {
        List<OrderResult> results = new List<OrderResult>();
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

        for (String orderId : orderNumbers) {
            OrderResult res = new OrderResult();
            String result;
            try {
                result = callIncidentAssistantAgent(orderId);
            } catch (Exception e) {
                result = 'Error: ' + e.getMessage();
            }
            res.orderId = orderId;
            res.analysisOutput = result;
            results.add(res);
        }

        return results;
    }

    private static String callIncidentAssistantAgent(String orderId) {
        Invocable.Action action = Invocable.Action.createCustomAction(
            STANDARD_AI_ACTION,
            AGENT_NAME
        );
        action.setInvocationParameter('orderIds', orderId);
        List<Invocable.Action.Result> results = action.invoke();
        Invocable.Action.Result result = results[0];

        if (result.isSuccess()) {
            String sessionId = (String) result.getOutputParameters().get('sessionId');
            String response = (String) result.getOutputParameters().get('agentResponse');
            return response;
        } else {
            throw new AgentPromptException('Action execution failed: ' + result.getErrors());
        }
    }

    public class AgentPromptException extends Exception {
    }
}
