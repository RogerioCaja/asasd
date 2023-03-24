@isTest
public class IntegrationINVisitsPlanningTest {
  
    @TestSetup
    static void makeData(){

        Safra__c safra = new Safra__c(
            Code__c = '111',
            Name = 'Safra Teste',
            Name__c = 'Safra Teste',
            BillingStartDate__c = System.today(),
            EndDateBilling__c = System.today(),
            EndDateInsertionOrders__c = System.today(),
            NumberOfDaysAfterPayment__c = System.today(),
            ReleaseStatus__c = 'Ativo',
            StartDateOrderInsertion__c = System.today()

        );
        insert safra;

        Account account = new Account(
            Name = 'Teste 1',
            BillingStreet = ' ',
            BillingState = '' ,
     
            Phone= '', 
            BpType__c = 'Proprietario',
            BillingCity = ' ', 
            BillingLongitude = 000000,
            BillingLatitude = 00000,
            BillingPostalCode = '',
            ExternalId__c = '11111',
            Company__c = 'Empresa 1'
        );
        insert account;
        Account account2 = new Account(
            Name = 'Teste 2',
            BillingStreet = ' ',
            BillingState = '' ,
            ParentId = account.Id,
            Phone= '', 
            BillingCity = ' ', 
            BpType__c = 'Propriedade',
            BillingLongitude = 000000,
            BillingLatitude = 00000,
            BillingPostalCode = '',
            ExternalId__c = '2222',
            Company__c = 'Empresa 1'
        );
        insert account2;
        
        
        Cultura__c cultura = new Cultura__c(
            Name = 'Safrinha',
            Name__c = 'Safrinha',
            Codigo__c = '1234'
        );
        insert cultura;
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(
            Alias = 'standt', Email='standarduser@testorg.com', CodigoSap__c = '010',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='testes_BP_TEST@testes.com');
        insert u;
    }
    
    @isTest
    static void verifyIntegrationINVisitPlanning(){
        List<TemplateDataIntegrationFields.FotosINData> photoList = new List<TemplateDataIntegrationFields.FotosINData>();
        TemplateDataIntegrationFields.FotosINData photo = new TemplateDataIntegrationFields.FotosINData();
        photo.Observation = 'test';
        photo.FileLine = '100';
        photo.Photo = 'iVBORw0KGgoAAAANSUhEUgAAA/cAAAJCCAIAAAAKlKDqAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAB/uSURBVHhe7dxhciu9kabRXtcsqNfTq5nNzGI84W+e7CFal7qURAokeM4v3xeoYrHETGQ4HP6PfwEAAGcx5QMAwGlM+QAAcBpTPgAAnMaUDwAApzHlAwDAaUz5AABwGlM+AACcxpQPAACnMeUDAMBpTPkAAHAaUz4AAJzGlA8AAKcx5QMAwGlM+QAAcBpTPgAAnMaUDwAApzHlAwDAaUz5AABwGlM+AACcxpQPAACnMeUDAMBpTPkAAHAaUz4AAJzGlA8AAKcx5QMAwGlM+QAAcBpTPgAAnMaUDwAApzHlAwDAaUz5AABwGlM+AACcxpQPAACnMeUDAMBpTPkAAHAaUz4AAJzGlA8AAKcx5QMAwGlM+QAAcBpTPgAAnMaUDwAApzHlAwDAaUz5AABwGlM+AACcxpQPAACnMeUDAMBpTPkAAHAaUz4AAJzGlA8AAKcx5QMAwGlM+QAAcBpTPgAAnMaUDwAApzHlAwDAaUz5AABwGlM+AACcxpQPAACnMeUDAMBpTPkAAHAaUz4AAJzGlA8AAKcx5QMAwGlM+QAAcBpTPgAAnMaUDwAApzHlAwDAaUz5AABwGlM+AACcxpQPAACnMeUDAMBpTPkAAHAaUz4AAJzGlA8AAKcx5QMAwGlM+QAAcBpTPgAAnMaUDwAApzHlAwDAaUz5AABwGlM+AACcxpQPAACnMeUDAMBpTPkAAHAaUz4AAJzGlA8AAKcx5QMAwGlM+QAAcBpTPgAAnMaUDwAApzHlAwDAaUz5AABwGlM+AACcxpQPAACnMeUDAMBpTPkAAHAaUz4AAJzGlA8AAKcx5QMAwGlM+QAAcBpTPgAAnMaUDwAApzHlAwDAaUz5AABwGlM+AACcxpQPAACnMeUDAMBpTPkAAHAaUz4AAJzGlA8AAKcx5QMAwGlM+QAAcBpTPgAAnMaUDwAApzHlAwDAaUz5AABwGlM+AACcxpQPAACnMeUDAMBpTPkAAHAaUz4AAJzGlA8AAKcx5QMAwGlM+QAAcBpTPgAAnMaUDwAApzHlAwDAaUz5AABwGlM+AACcxpQPAACnMeUDAMBpTPkAAHAaUz4AAJzGlA8AAKcx5QMAwGlM+a/hPwDgbXT4AT+gkJ5a3Q4A3lLHIfB16udJ1d4A4O11NAJfoXKeUV0NABidkcBt1MzTqZkBAKtOSuAGCuaJ1MOuaBMAHK1j74o2AX+jWp5IDeyDlgHgnXQKftAy8Cml8ixqXavWAOBddSKuWgOuUydPoaa1ag0A3lvn4qo14ApFsl/tatUaAOCshK9TIfvVqy60AACMzsgLLQB/okI2q1FdaAEAWHVSXmgB+EB5bFaXutACALDqpLzQAvCB8tisLjVKAYA/6bwcpcAHymOnWtSFFgCAP+m8vNACsFIbO9WfRikAcF2n5igFVmpjp/rTKAUAruvUHKXASm3sVH8apQDAdZ2aoxRYqY2d6k+jFAC4rlNzlAIrtbFT/WmUAgDXdWqOUmClNnaqP41S4IsqoafUIwL3U3WNUmClNnaqP41SeEuVARd6NcCqChmlwEpt7FR/GqVwhH7W/JbeO7yBfvSjFFipjZ3qT6MUXkQ/XF5EfzZ4ff2mRymwUhs71Z9GKTyHfpe8jf7w8PT6yY5SYKU2dqo/jVL4Xf3+XlBf4Ln1rK+sbwJPo5/mKAVWamOn+tMohcfod/aUekRWvZ1n1VPCr+snOEqBldrYqf40SuFn+j3t1tPwi3r1u/U08DD91EYpsFIbO9WfRincrJ/OJj0Er6O/3A49AdxDv6pRCqzUxk71p1EK1/Vb+RV9JG+jP/xv6VPh6/oNjVJgpTZ2qj+NUhj9Mh6sD4Mr+qE8WB8GN+hHM0qBldrYqf40SnlX/Q4epo+BO+mH9TB9DHzQT2SUAiu1sVP9aZTyHvqrP0afAb+un+Bj9Bm8vX4QoxRYqY2d6k+jlEP1Z7637g5PrB/rvXV33k+/gFEKrNTGTvWnUcop+rveVbeGF9cP+q66NW+gP/koBVZqY6f60yjllfW3vJNuCm+gH/2ddFMO1Z95lAIrtbFT/WmU8mr6+91DdwRUFtf1dx2lwEpt7FR/GqU8vf5gP9btgBtUNj/W7Xhl/S1HKbBSGzvVn0YpT6k/0s90L+DHKqqf6V68mv5+oxRYqY2d6k+jlKfRH+YHuhHwYJXcD3QjXkF/s1EKrNTGTvWnUcpu/T2+pVsAW1WQ39VdeFb9nUYpsFIbO9WfRik79Df4lm4BPKUK9Vu6BU+mP88oBVZqY6f60yjlt/Tev6VbAC+lAv6WbsET6E8ySoGV2tip/jRKebBe99d1PXCECvvrup59+kuMUmClNnaqP41SHqBX/HVdDxytgv+6rud39fZHKbBSGzvVn0Yp99Ob/aIuBt5SjeCLuphf0UsfpcBKbexUfxql/Fgv9Iu6GOAftYYv6mIeqXc9SoGV2tip/jRK+a7e41d0JcCnahlf0ZU8QK94lAIrtbFT/WmU8kW9vq/oSoCvq4/crMu4n97sKAVWamOn+tMo5Ta9tZt1GcCd1Fxu1mX8WC90lAIrtbFT/WmU8qle1s26DOBhajc36zK+q/c4SoGV2tip/jRKuaLXdJuuAfhFNaDbdA1f1xscpcBKbexUfxqlrHo7t+kagK1qSbfpGm7WixulwEpt7FR/GqX8o5dym64BeDI1qdt0DX/T+xqlwEpt7FR/GqVvr9dxgy4AeHq1rRt0Adf1pkYpsFIbO9WfRum76i3coAsAXlCN7AZdwAe9oFEKrNTGTvWnUfp++v436AKA11df+5t2c6FXM0qBldrYqf40St9J3/xv2g1wnNrc37Sbf/RSRimwUhs71Z9G6RvoC/9NuwHeQI3vb9r93noXoxRYqY2d6k+j9Gh91b9pN8CbqQn+TbvfVW9hlAIrtbFT/WmUHqov+am2Ary92uKn2vp++v6jFFipjZ3qT6P0OH29T7UVgAu1yE+19Z30zUcpsFIbO9WfRulB+mKfaisAV9QuP9XW99B3HqXASm3sVH8apUfoK13XPgBuVgO9rn2n69uOUmClNnaqP43SF9eXua59AHxLzfS69p2r7zlKgZXa2Kn+NEpfVl/juvYB8GM11uvad6K+4SgFVmpjp/rTKH1BfYHr2gfAXdVkr2vfWfpuoxRYqY2d6k+j9KX06Ne1D4CHqeFe175T9K1GKbBSGzvVn0bpi+ihr2sfAL+i5ntd+15f32eUAiu1sVP9aZS+gp74ijYB8OtqxFe06cX1ZUYpsFIbO9WfRulz61mvaBMAW9WUr2jTy+prjFJgpTZ2qj+N0mfVU17RJgCeRg36ija9oL7AKAVWamOn+tMofUo94p+0A4CnVLP+k3a8mp5+lAIrtbFT/WmUPpke7oo2AfDEatlXtOl19NyjFFipjZ3qT6P0afRYV7QJgBdR+76iTa+gJx6lwEpt7FR/GqXPoWf6k3YA8IJq5X/SjqfX445SYKU2dqo/jdIn0AP9STsAeFk19D9px3PrWUcpsFIbO9WfRulWPcqftAOAI9Tc/6Qdz6qnHKXASm3sVH8apfv0HB+0DMBxavQftPyUesRRCqzUxk71p1G6Q0/wJ+0A4FC1+z9px5Pp4UYpsFIbO9WfRumv6+P/pB0AnK6+/0HLz6QnG6XASm3sVH8apb+rz/6gZQDeRgfABy0/jR5rlAIrtbFT/WmU/qI++IOWAXgzHQN/0o4n0AONUmClNnaqP43SX9FHftAyAG+sI+GDlnfraUYpsFIbO9WfRunj9XkftAzA2+tg+KDlrXqUUQqs1MZO9adR+mB92ActA8A/Oh4+aHmfnmOUAiu1sVP9aZQ+Up/0QcsAsOqcWLW2SQ8xSoGV2tip/jRKH6aPWbUGAFd0YKxa26EnGKXASm3sVH8apY/RZ6xaA4BPdWysWvt1ffwoBVZqY6f60yh9gD5g1RoA3KDDY9Xa7+qzRymwUhs71Z9G6b1191VrAHCzjpBVa7+oDx6lwEpt7FR/GqV31a1XrQHAF3WQrFr7LX3qKAVWamOn+tMovZ/uu2oNAL6l42TV2q/oI0cpsFIbO9WfRumddNNVawDwAx0qq9Yer88bpcBKbexUfxql99AdV60BwI91tKxae7A+bJQCK7WxU/1plP5Yt1u1BgB30gGzau2R+qRRCqzUxk71p1H6Y93uQgsAcFcdMxdaeKQ+aZQCK7WxU/1plP5M97rQAgA8QIfNhRYepo8ZpcBKbexUfxqlP9CNLrQAAA/TkXOhhcfoM0YpsFIbO9WfRul3dZdVawDwMB05q9YeoA8YpcBKbexUfxql39VdLrQAAA/WwXOhhQfoA0YpsFIbO9WfRum3dIsLLQDAr+j4udDCvXX3UQqs1MZO9adR+nVdf6EFAPhFHUIXWrirbj1KgZXa2Kn+NEq/rusvtAAAv6hD6EILd9WtRymwUhs71Z9G6Rd18YUWAODXdRRdaOF+uu8oBVZqY6f60yj9oi4epQCwSQfSKL2f7jtKgZXa2Kn+NEq/oisvtAAAm3QgXWjhTrrpKAVWamOn+tMo/YquHKUAsFXH0ii9k246SoGV2tip/jRKb9ZlF1oAgK06li60cA/dcZQCK7WxU/1plN6sy0YpADyBDqdReg/dcZQCK7WxU/1plN6may60AABPoMPpQgs/1u1GKbBSGzvVn0bpbbpmlALA0+iIGqU/1u1GKbBSGzvVn0bpbbpmlALA0+iIGqU/1u1GKbBSGzvVn0bpDbrgQgsA8Ew6pUbpz3SvUQqs1MZO9adReoMuGKUA8GQ6qEbpz3SvUQqs1MZO9adReoMuGKUA8GQ6qEbpz3SvUQqs1MZO9adR+jftHqUA8JQ6rkbpD3SjUQqs1MZO9adR+jftHqUA8JQ6rkbpD3SjUQqs1MZO9adR+jftHqUA8JQ6rkbpD3SjUQqs1MZO9adR+jftHqUA8JQ6rkbpD3SjUQqs1MZO9adR+jftHqUA8JQ6ri608F3dZZQCK7WxU/1plH6qraMUAJ5Yh9Yo/a7uMkqBldrYqf40Sj/V1lEKAE+sQ2uUfld3GaXASm3sVH8apZ9q6ygFgCfWoTVKv6u7jFJgpTZ2qj+N0k+1dZQCwBPr0Bql39VdRimwUhs71Z9G6afaOkqBr/o///W/KqN/+1//9X/K//Wv//2f67+BH6vSRul3dZdRCqzUxk71p1H6qbaOUuBL/j3I/8d//u/+9f8mfoM9PM7/O7P+W+l3dZdRCqzUxk71p1H6qbaOUuAL/j3U/8+Z/t9zf2P/xX8E7qNDa5R+V3cZpcBKbexUfxqln2rrKAVu96ch/5/ZvtCUD3fXoTVKv6u7jFJgpTZ2qj+N0k+1dZQCt/v3lP9xiv//s70pH+6uQ2uUfld3GaXASm3sVH8apZ9q6ygFbue/y4df16E1Sr+ru4xSYKU2dqo/jdJPtXWUAl/wpzH+IjPlw911aI3S7+ouoxRYqY2d6k+j9FNtvdACcLP/+f+ps/7blA9314k1Sr+ru4xSYKU2dqo/jdK/afcoBb7k37P8f1v+BzymfLiv6myU/kA3GqXASm3sVH8apX/T7lEKAE+p42qU/kA3GqXASm3sVH8apX/T7lEKAE+p42qU/kA3GqXASm3sVH8apX/T7lEKAE+p42qU/kA3GqXASm3sVH8apTfoglEKAE+mg+pCCz/QjUYpsFIbO9WfRukNumCUAsCT6aAapT/TvUYpsFIbO9WfRukNumCUAsCT6aAapT/TvUYpsFIbO9WfRultumaUAsDT6Ii60MLPdK9RCqzUxk71p1F6m64ZpQDwNDqiRumPdbtRCqzUxk71p1F6m6650AIAPIEOpwst/Fi3G6XASm3sVH8apTfrslEKAE+gw2mU3kN3HKXASm3sVH8apTfrsgstAMBWHUsXWriH7jhKgZXa2Kn+NEq/oitHKQBs1bE0Su+km45SYKU2dqo/jdKv6MoLLQDAJh1IF1q4k246SoGV2tip/jRKv6iLRykAbNKBNErvp/uOUmClNnaqP43SL+riCy0AwK/rKLrQwv1031EKrNTGTvWnUfp1XX+hBQD4RR1CF1q4q249SoGV2tip/jRKv67rL7QAAL+oQ+hCC3fVrUcpsFIbO9WfRum3dIsLLQDAr+j4udDCvXX3UQqs1MZO9adR+l3d5UILAPBgHTwXWniAPmCUAiu1sVP9aZR+V3dZtQYAj9Spc6GFB+gDRimwUhs71Z9G6Q90owstAMDDdORcaOEx+oxRCqzUxk71p1H6M93rQgsA8AAdNhdaeJg+ZpQCK7WxU/1plP5Yt7vQAgDcVcfMqrWH6WNGKbBSGzvVn0bpj3W7VWsAcCcdMKvWHqlPGqXASm3sVH8apffQHVetAcCPdbSsWnuwPmyUAiu1sVP9aZTeSTddtQYAP9Chsmrt8fq8UQqs1MZO9adRej/dd9UaAHxLx8mqtV/RR45SYKU2dqo/jdK76tar1gDgizpIVq39lj51lAIrtbFT/WmU3lt3X7UGADfrCFm19ov64FEKrNTGTvWnUfoAfcCqNQC4QYfHqrXf1WePUmClNnaqP43Sx+gzVq0BwKc6Nlat/bo+fpQCK7WxU/1plD5MH7NqDQCu6MBYtbZDTzBKgZXa2Kn+NEofqU/6oGUAWHVOrFrbpIcYpcBKbexUfxqlD9aHfdAyAPyj4+GDlvfpOUYpsFIbO9WfRunj9XkftAzA2+tg+KDlrXqUUQqs1MZO9adR+iv6yA9aBuCNdSR80PJuPc0oBVZqY6f60yj9RX3wBy0D8GY6Bv6kHU+gBxqlwEpt7FR/GqW/q8/+oGUA3kYHwActP40ea5QCK7WxU/1plP66Pv6DlgF4A7X+D1p+Jj3ZKAVWamOn+tMo3aEn+JN2AHCo2v2ftOPJ9HCjFFipjZ3qT6N0n57jg5YBOE6N/oOWn1KPOEqBldrYqf40SrfqUf6kHQAcoeb+J+14Vj3lKAVWamOn+tMo3a2nuaJNALyyevqftOOJ9aCjFFipjZ3qT6P0OfRMf9IOAF5QrfxP2vH0etxRCqzUxk71p1H6NHqsK9oEwIuofV/RplfQE49SYKU2dqo/jdIn08Nd0SYAnltd+0/a8Tp67lEKrNTGTvWnUfqUesQ/aQcAT6lmfUWbXkqPPkqBldrYqf40Sp9VT3lFmwB4GjXoK9r0gvoCoxRYqY2d6k+j9Ln1rFe0CYCtaspXtOll9TVGKbBSGzvVn0bp0+txr2sfAL+uRnxd+15Z32SUAiu1sVP9aZS+iB76uvYB8Ctqvte17/X1fUYpsFIbO9WfRulL6dGvax8AD1PDva59p+hbjVJgpTZ2qj+N0hfUF7iufQDcVU32uvadpe82SoGV2tip/jRKX1Zf47r2AfBjNdbr2neivuEoBVZqY6f60yh9cX2Z69oHwLfUTK9r37n6nqMUWKmNnepPo/QIfaXr2gfAzWqg17XvdH3bUQqs1MZO9adRepC+2HXtA+BTNc1PtfUN9IVHKbBSGzvVn0bpcfp6n2orABdqkZ9q6zvpm49SYKU2dqo/jdJD9SU/1VaAt1db/FRb30/ff5QCK7WxU/1plB6tr/o37QZ4MzXBv2n3u+otjFJgpTZ2qj+N0jfQF/6bdgO8gRrf37T7vfUuRimwUhs71Z9G6Tvpm/9NuwGOU5u7QRfg9ITbqI2d6k+j9P30/f+m3QBHqLX9Tbu50KsZpcBKbexUfxql76q3cIMuAHhBNbIbdAEf9IJGKbBSGzvVn0bp2+t13KALAJ5ebesGXcB1valRCqzUxk71p1HKP3opt+kagCdTk7pN1/A3va9RCqzUxk71p1HKqrdzm64B2KqWdJuu4Wa9uFEKrNTGTvWnUcqf9I5u1mUAv6gGdLMu44t6faMUWKmNnepPo5RP9bJu1mUAD1O7uVmX8V29x1EKrNTGTvWnUcptems36zKAO6m53KzL+LFe6CgFVmpjp/rTKOWLen036zKAb6mV3KzLuJ/e7CgFVmpjp/rTKOW7eo9f0ZUAn6plfEVX8gC94lEKrNTGTvWnUcqP9UK/oisBLtQgvqIreaTe9SgFVmpjp/rTKOV+erNf1MXAW6oRfFEX8yt66aMUWKmNnepPo5QH6BV/XdcDR6vgv67r+V29/VEKrNTGTvWnUcqD9bq/ruuBI1TY39It2KQ/wygFVmpjp/rTKOW39N6/pVsAr6Ya/rqu5wn0JxmlwEpt7FR/GqXs0N/gW7oF8JQq1G/pFjyZ/jyjFFipjZ3qT6OUrfpjfFd3AbaqIL+ru/Cs+juNUmClNnaqP41SnkZ/mB/oRsCDVXI/0I14Bf3NRimwUhs71Z9GKU+pP9LPdC/gxyqqn+levJr+fqMUWKmNnepPo5Sn1x/sZ7oXcLOK52e6F6+sv+UoBVZqY6f60yjlpfTHu4fuCPyjwriH7sgp+ruOUmClNnaqP41SXll/yzvppvAG+tHfSTflUP2ZRymwUhs71Z9GKafo73pX3RpeXD/ou+rWvIH+5KMUWKmNnepPo5RD9We+q24NT6+f7F11a95Pv4BRCqzUxk71p1HKe+iv/gB9AGzSD/EB+gDeXj+IUQqs1MZO9adRyrvqd/AwfQzcST+sh+lj4IN+IqMUWKmNnepPoxT+0c/iwfow+FQ/lwfrw+Bv+sWMUmClNnaqP41SuKIfyq/oI3kz/fl/RR8JX9dvaJQCK7WxU/1plMLN+uns0BPwUvrj7dATwD30qxqlwEpt7FR/GqXwM/2edutp+EW9+t16GniYfmqjFFipjZ3qT6MUHqPf2VPqEfmgF/Ssekr4Xf3+RimwUhs71Z9GKfyifnwvri/z3HrW19R3gOfQ73KUAiu1sVP9aZTCE+hHyZvpzw/Prd/rKAVWamOn+tMohVfQr5aX0h8PXlw/6FEKrNTGTvWnUQpH6GfNL+rVw+n6xY9SYKU2dqo/jVJ4P9UAH/SCgAuVxygFVmpjp/rTKAW+qBJ6Sj0icD9V1ygFVmpjp/rTKAUAruvUHKXASm3sVH8apQDAdZ2aoxRYqY2d6k+jFAC4rlNzlAIrtbFT/WmUAgDXdWqOUmClNnaqP41SAOC6Ts1RCqzUxk71p1EKAFzXqTlKgZXa2Kn+NEoBgOs6NUcpsFIbO9WfRikAcF2n5igFVmpjp/rTKAUAruvUHKXASm3sVH8apQDAdZ2aoxRYqY2d6k+jFAC4rlNzlAIrtbFT/elCCwDAn3ReXmgBWKmNzWpRoxQA+JPOy1EKfKA8NqtLjVIA4E86L0cp8IHy2KwudaEFAGDVSXmhBeAD5bFfjepCCwDA6Iy80ALwJypkv3rVqjUAwFkJX6dCnkLtatUaALy3zsVVa8AViuRZ1LRWrQHAu+pEXLUGXKdOnkV960/aAQDvpFPwg5aBTymVJ1L3uqJNAHC6Tr4r2gR8Sqk8nXoYALDqpARuoGCeUc0MABidkcBt1MyTqqUBwNvraAS+QuU8tdobALyrTkTgixTPa6jVAcAb6PADfkAhAQDAaUz5AABwGlM+AACcxpQPAACnMeUDAMBpTPkAAHAaUz4AAJzGlA8AAKcx5QMAwGlM+QAAcBpTPgAAnMaUDwAApzHlAwDAaUz5AABwGlM+AACcxpQPAACnMeUDAMBpTPkAAHAaUz4AAJzGlA8AAKcx5QMAwGlM+QAAcBpTPgAAnMaUDwAApzHlAwDAaUz5AABwGlM+AACcxpQPAACnMeUDAMBpTPkAAHAaUz4AAJzGlA8AAKcx5QMAwGlM+QAAcBpTPgAAnMaUDwAApzHlAwDAaUz5AABwGlM+AACcxpQPAACnMeUDAMBpTPkAAHAaUz4AAJzGlA8AAKcx5QMAwGlM+QAAcBpTPgAAnMaUDwAApzHlAwDAaUz5AABwGlM+AACcxpQPAACnMeUDAMBpTPkAAHAaUz4AAJzGlA8AAKcx5QMAwGlM+QAAcBpTPgAAnMaUDwAApzHlAwDAaUz5AABwGlM+AACcxpQPAACnMeUDAMBpTPkAAHAaUz4AAJzGlA8AAKcx5QMAwGlM+QAAcBpTPgAAnMaUDwAApzHlAwDAaUz5AABwGlM+AACcxpQPAACnMeUDAMBpTPkAAHAaUz4AAJzGlA8AAKcx5QMAwGlM+QAAcBpTPgAAnMaUDwAApzHlAwDAaUz5AABwGlM+AACcxpQPAACnMeUDAMBpTPkAAHAaUz4AAJzGlA8AAKcx5QMAwGlM+QAAcBpTPgAAnMaUDwAApzHlAwDAaUz5AABwGlM+AACcxpQPAACnMeUDAMBpTPkAAHAaUz4AAJzGlA8AAKcx5QMAwGlM+QAAcBpTPgAAnMaUDwAApzHlAwDAaUz5AABwGlM+AACcxpQPAACnMeUDAMBpTPkAAHAaUz4AAJzGlA8AAKcx5QMAwGlM+QAAcBpTPgAAnMaUDwAApzHlAwDAaUz5AABwGlM+AACcxpQPAACnMeUDAMBpTPkAAHAaUz4AAJzGlA8AAKcx5QMAwGlM+QAAcBpTPgAAnMaUDwAApzHlAwDAaUz5AABwGlM+AACcxpQPAACnMeUDAMBpTPkAAHAaUz4AAJzGlA8AAKcx5QMAwGlM+QAAcBpTPgAAnMaUDwAApzHlAwDAaUz5AABwGlM+AACcxpQPAACnMeUDAMBpTPkAAHAaUz4AAJzGlA8AAKcx5QMAwGlM+QAAcBpTPgAAnMaUDwAApzHlAwDAaUz5AABwGlM+AACcxpQPAACnMeUDAMBpTPkAAHAaUz4AAJzGlA8AAKcx5QMAwGlM+QAAcBpTPgAAnMaUDwAApzHlAwDAaUz5AABwGlM+AACcxpQPAACnMeUDAMBpTPkAAHAaUz4AAJzGlA8AAKcx5QMAwGlM+QAAcBpTPgAAnMaUDwAApzHlAwDAaUz5AABwGlM+AACcxpQPAACnMeUDAMBZ/vWv/wuQTmucYbTCfQAAAABJRU5ErkJggg==';
        photoList.add(photo);


        List<TemplateDataIntegrationFields.TechnicalReportINData> technicalList = new List<TemplateDataIntegrationFields.TechnicalReportINData>();
        TemplateDataIntegrationFields.TechnicalReportINData technical = new TemplateDataIntegrationFields.TechnicalReportINData();
        technical.Observation = 'test';
        technical.EndTime = Time.newInstance(18, 30, 2, 20);
        technical.EndDate = Date.valueOf('2022-09-23');
        technical.Status = 'Gerado';
        technical.RtrLine = '30';
        technical.Photos = new List<TemplateDataINtegrationFields.FotosINData>();
        technical.Photos.addAll(photoList);
        technicalList.add(technical);


        List<TemplateDataIntegrationFields.VisitPlanningINData> visitList = new List<TemplateDataIntegrationFields.VisitPlanningINData>();
        TemplateDataIntegrationFields.VisitPlanningINData visit = new TemplateDataIntegrationFields.VisitPlanningINData();
        visit.Name = 'Test';
        visit.BpCode = '11111';
        visit.ExternalIdApp = 'test';
        visit.BpPropertyCode = '2222';
        visit.PlanStartDate = Date.valueOf('2022-09-21');
        visit.PlanEndDate = Date.valueOf('2022-09-23');
        visit.StartTime = Time.newInstance(18, 30, 2, 20);
        visit.EndTime = Time.newInstance(18, 30, 2, 22);
        visit.Status = 'Agendado';
        visit.Objective = 'Evento';
        visit.Crop = '111';
        visit.Culture = '1234';
        visit.Email = 'test@gmail.com';
        visit.Presential = true;
        visit.Reminder = false;
        visit.Displacement  = 'Sim';
        visit.CtvVisit = '010';
        visit.Observation = 'test1';
        visit.ReasonRescheduling = 'test1';
        visit.ReasonCancellation = 'test1';
        visit.TechnicalReports = new List<TemplateDataINtegrationFields.TechnicalReportINData>();
        visit.TechnicalReports.addAll(technicalList);
        visitList.add(visit);
        
        Test.startTest();
        IntegrationINVisitsPlanning.ResponseModel model = IntegrationINVisitsPlanning.upsertVisitsPlanning(visitList);
        Test.stopTest();
        
        System.debug(model);
    }
}