public class TemplateDefaultFields {
	
    public interface FieldDefaults { 
        Map<String, Object> getFieldDefaults();
    }

    public class UserDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults(){
            return new Map<String, Object>{
                'CompanyName'       => 'TEST',
                'EmailEncodingKey'  => 'UTF-8',
                'TimeZoneSidKey'    => 'America/Sao_Paulo',
                'LocaleSidKey'      => 'pt_BR',
                'LanguageLocaleKey' => 'pt_BR'
            };
        }
    }

    public class AccountDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'Name' 				       => 'Acc Teste',
                // 'Status__c'			       => 'New',
                'BillingCountryCode'       => 'BR',
                'CNPJ__c'                  => '09210030000105',
                'FiscalEmail__c'           => 'teste@teste.com.invalid',
                'AccountSource'            => 'Televendas',
                'BillingStreet'            => 'Rua das Margaridas',
                'BillingAddressNumber__c'  => '258',
                'BillingDistrict__c'       => 'Bairro Jardins',
                'BillingComplement__c'     => 'Perto da Floricultura',
                'BillingStateCode'         => 'SP',
                'BillingPostalCode'        => '00000000',
                'BillingCity'              => 'Cidade das Flores',
                'FormTaxation__c'          => 'Simples',
                'InternalSpecialRegime__c' => 'Sim',
                'StateRegistration__c'     => '264402937871',
                'SuframaCode__c'           => '147852369',
                'EstablishmentType__c'     => 'Matriz',
                'PCIMember__c'             => 'Não',
                'Status__c'                => 'WaitingDEPS',
                'RegistrationStatus__c'    => 'Não Validado/Novo',
                'TypeOfNegotiation__c'     => 'Negociação Direta'
            };
        }
    }
    
    public class CNAEDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'Name' => 'CNAE Teste'
            };
        }
    }
    
    public class CustomerGroupDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'Name' => 'Grupo cliente Teste'
            };
        }
    }
    
    public class BillingGroupDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'Name' => 'Grupo Cobrança Teste'
            };
        }
    }

    public class BusinessUnitDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{};
        }
    }

    public class SegmentDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{};
        }
    }

    public class CommerceEntitlementPolicyDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'BatchInProgress__c' => false
            };
        }
    }

    public class CommerceEntitlementProductDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{};
        }
    }

    public class SalesDiscountRangesDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{};
        }
    }
    
    public class LeadDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'FirstName'           => 'Lead',
				'LastName'            => '- Teste',
                'Company'             => 'ABC Company',
                'Email'               => 'testlead@mail.com',
                'Phone'               => '11935874410',
                'Street'              => 'Rua das Margaridas',
                'District__c'         => 'Jardins',
                'City'                => 'São Bernardo do Campo',
                'State'               => 'São Paulo',
                'Country'             => 'Brazil',
                'PostalCode'          => '09752400',
                'EvaluationStatus__c' => 'Não atingiu as Premissas'
            };
        }
    }

    public class OpportunityDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'Name' 				 => 'Opp Teste',
                'StageName'			 => 'Qualificação'
            };
        }
    }

    public class PaymentConditionDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'Name'          => 'Condição pgto teste',
                'ExternalId__c' => '123456'
            };
        }
    }

    public class AccountPaymentConditionDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{};
        }
    }


    public class Pricebook2Defaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'Name'              => 'Pricebook teste',
                'ExternalId__c'     => '789456',
                'UFDestination__c'  => 'SP',
                'PriceGroupCode__c' => '123456',
                'IsActive'          => true
            };
        }
    }

    public class ProductCatalogDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'Name'          => 'Catalogo teste',
                'IsStandard__c' => true
            };
        }
    }

    public class Product2Defaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'Name'                      => 'Produto Teste',
                'Family'                    => 'ALARMES',
                'IsActive'                  => true,
                'AvailableForAttendance__c' => false,
                'IgnoreTestClasses__c'      => true
            };
        }
    }

    public class PriceBookEntryDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{};
        }
    }

    public class QuoteDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'Name'                     => 'Cotação teste',
                'Status'                   => 'Rascunho',
                'PurchaseGoal__c'          => 'Revenda / Industrialização',
                'CustomerType__c'          => 'Teste',
                'StateRegistration__c'     => '264402937871',
                'SuframaCode__c'           => '147852369'
            };
        }
    }

    public class QuoteLineItemDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'Quantity' => 5,
                'CommercialDiscount__c' => 10
            };
        }
    }

    public class OrderDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'Status' => 'Novo'
            };
        }
    }

    public class OrderItemDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'Quantity' => 5,
                'CommercialDiscount__c' => 10
            };
        }
    }

    public class CaseDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'Origin' => 'Oportunidade',
                'Status' => 'Novo'
            };
        }
    }

    public class FormDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'Name'                      => 'Formulário 1',
                'Active__c'                 => true,
                'AvailableForAttendance__c' => true,
                'AvailableForSales__c'      => true
            };
        }
    }

    public class FormProductDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{};
        }
    }

    public class ProductPortfolioDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{};
        }
    }

    public class ProductPaymentConditionDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{};
        }
    }
    
    public class AccountCustomerGroupDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{};
        }
    }

    public class FormQuestionDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{};
        }
    }

    public class FormAnswerDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                
            };
        }
    }

    public class EntitlementDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{};
        }
    }

    public class EstablishmentDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'District__c'          => 'Distrito Industrial',
                'ZIPCode__c'           => '88104765',
                'City__c'              => 'São José',
                'CNPJ__c'              => '79009965000103',
                'StateCode__c'         => 'SP',
                'StateRegistration__c' => '250.087.499',
                'StreetAdress__c'      => 'Rua Judite Melo dos Santos; 205;',
                'CountryCode__c'       => 'Brasil'
            };
        }
    }

    public class ProductKitItemDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'ItemQuantity__c'    => 5,
                'KitItemDiscount__c' => 1
            };
        }
    }

    public class ContactDefaults implements FieldDefaults{
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'FirstName'         => 'Carlos',
                'LastName'          => 'Almeida',
                'DocumentNumber__c' => '29841241544',
                'Phone'             => '74905824428',
                'Email'             => 'teste@teste1.com'                
            };
        }
    }

    public class ContractDefaults implements FieldDefaults{
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'Name'            => 'Teste',
                'StartDate'       => System.today(),
                'ContractTerm'    => 12,
                'ContractType__c' => 'Venda',
                'Status'          => 'Em Elaboração'                
            };
        }
    }

    public class ContractedProductDefaults implements FieldDefaults{
        public Map<String, Object> getFieldDefaults(){
            return new Map<String, Object>{
                'ConsumedQuantity__c'  => 0,
                'AvailableQuantity__c' => 30
            };
        }
    }

    public class AssetDefaults implements FieldDefaults{
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'Name' => 'Ativo teste'               
            };
        }
    }

    public class CampaignDefaults implements FieldDefaults{
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'Name'      => 'Campanha teste',
                'IsActive'  => true,
                'StartDate' => System.today(),
                'EndDate'   => System.today().addDays(45)            
            };
        }
    }

    public class CampaignMemberDefaults implements FieldDefaults{
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'Status' => 'Novo'
            };
        }
    }

    public class WebCartDefaults implements FieldDefaults{
        public Map<String, Object> getFieldDefaults() {
            return new Map<String, Object>{
                'PurchaseGoal__c' => 'Consumo Próprio',
                'Name'            => 'Cart',
                'Status'          => 'Active'
            };
        }
    }

    public class WebStoreDefaults implements FieldDefaults{
        public Map<String, Object> getFieldDefaults(){
            return new Map<String, Object>{
                'Name'  => 'WebStore Test'
            };
        }
    }

    public class BuyerGroupDefaults implements FieldDefaults{
        public Map<String, Object> getFieldDefaults(){
            return new Map<String, Object>{
                'Name'  => 'BuyerGroup Test'
            };
        }
    }

    public class BuyerGroupMemberDefaults implements FieldDefaults{
        public Map<String, Object> getFieldDefaults(){
            return new Map<String, Object>{};
        }
    }

    public class BuyerAccountDefaults implements FieldDefaults{
        public Map<String, Object> getFieldDefaults(){
            return new Map<String, Object>{
                'IsActive' => true,
                'Name'     => 'Buyer Account Test'
            };
        }
    }

    public class BuyerGroupPricebookDefaults implements FieldDefaults{
        public Map<String, Object> getFieldDefaults(){
            return new Map<String, Object>{};
        }
    }

    public class CartItemDefaults implements FieldDefaults{
        public Map<String, Object> getFieldDefaults(){
            return new Map<String, Object>{
                'Quantity' => 1,
                'Name'     => 'Cart Item Test'
            };
        }
    }

    public class CartDeliveryGroupDefaults implements FieldDefaults{
        public Map<String, Object> getFieldDefaults(){
            return new Map<String, Object>{
                'Name' => 'Cart Delivery Group Test'
            };
        }
    }

    public class AccountPriceGroupDefaults implements FieldDefaults{
        public Map<String, Object> getFieldDefaults(){
            return new Map<String, Object>{
                'Name' => 'Account PriceGroup Test'
            };
        }
    }

    public class PriceGroupDefaults implements FieldDefaults{
        public Map<String, Object> getFieldDefaults(){
            return new Map<String, Object>{
                'Name' => 'Price Group Test'
            };
        }
    }
}