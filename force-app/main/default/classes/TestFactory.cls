public class TestFactory {

    // Default Fields For SObjects
    private static final String DEFAULT_FIELD_FOR_SOBJECTS = 'Name';
	@TestVisible
    private static void validateSObject(SObject SObj) {
        if (sObj == null) {
            throw new TestFactoryException('SObject cannot be null');
        }
    }

    private static void addFieldDefaults(SObject sObj, Map<String, Object> defaultFields) {
        for (String field : defaultFields.keySet()) {
            if (sObj.get(field) == null) {
                sObj.put(field, defaultFields.get(field));
            }   
        }
    }

    public static SObject createSObject(SObject sObj) {
        validateSObject(sObj);

        String objectName = String.valueOf(sObj.getSObjectType());
        String defaultClassName = 'TemplateDefaultFields.' + objectName.replaceAll('__c|__mdt|__|_', '') + 'Defaults';
        sObj = dispatchSObjectCreation(sObj, defaultClassName);

        return sObj;
    }
    
	@TestVisible
    private static SObject dispatchSObjectCreation(SObject sObj, String defaultClassName) {
        Type t = Type.forName(defaultClassName);
        if (t == null) {
            throw new TestFactoryException('Invalid defaults class.');
        }
        TemplateDefaultFields.FieldDefaults defaults = (TemplateDefaultFields.FieldDefaults) t.newInstance();
        addFieldDefaults(sObj, defaults.getFieldDefaults());
        return sObj;
    }
    
    public class TestFactoryException extends Exception {
    }
}