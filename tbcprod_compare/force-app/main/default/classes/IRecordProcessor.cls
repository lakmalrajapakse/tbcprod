/**
*   @description Record processor interface
**/
public interface IRecordProcessor {
    void processRecords(List<Id> recordIds);
    void finish(List<Id> recordIds);
}