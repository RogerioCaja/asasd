public class QConditionGroup {
    
    public List<QCondition> conditions = new List<QCondition>();

    public String logicalOperator {
		public get { return String.escapeSingleQuotes(logicalOperator); }
		public set;
	}
    
    public QConditionGroup(List<QCondition> conditions) {
        this.conditions = conditions;
        this.logicalOperator = '';
    }

    public QConditionGroup setLogicalOperatorAsOr(){
        this.logicalOperator = ' OR ';
        return this;
    }

    public QConditionGroup setLogicalOperatorAsAnd(){
        this.logicalOperator = ' AND ';
        return this;
    }

}