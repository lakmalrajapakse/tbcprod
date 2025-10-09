import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { handleTransactionError } from "c/utils";
import getPayQueries from "@salesforce/apex/PayQueriesListViewController.getPayQueries";
import PayQueriesListViewNew from "c/payQueriesListViewNew";

export default class PayQueriesListView extends NavigationMixin(LightningElement) {
    _recordId;
    _gettingPayQueries = false;

    _data = [];
    _columns = [
        {
            label: "Name",
            fieldName: "url",
            type: "url",
            typeAttributes: { label: { fieldName: "name" }, target: "_blank" }
        },
        { label: "Type", fieldName: "type", initialWidth: 140 },
        { label: "Status", fieldName: "status" }
    ];

    @api
    set recordId(value) {
        this._recordId = value;
        this.reload();
    }
    get recordId() {
        return this._recordId;
    }

    get hasData() {
        return this._data.length > 0;
    }

    get isLoading() {
        return this._gettingPayQueries;
    }

    async reload() {
        try {
            if (!this.recordId) return;

            this._gettingPayQueries = true;
            const responseData = await getPayQueries({
                contactId: this.recordId
            });

            // Clone the data so that we can modify it
            const clonedData = responseData.map((x) => {
                return { ...x, url: "" };
            });

            for (let record of clonedData) {
                // eslint-disable-next-line no-await-in-loop
                record.url = await this.generateUrlForRecordId(record.id);
            }

            this._data = clonedData;

            console.log(JSON.stringify(this._data));
        } catch (ex) {
            handleTransactionError("Load error", ex);
        } finally {
            this._gettingPayQueries = false;
        }
    }

    async handleRefreshClick() {
        await this.reload();
    }

    async handleNewClick() {
        const result = await PayQueriesListViewNew.open({
            size: "small",
            contactId: this.recordId
        });

        if (result) {
            await this.reload();
        }
    }

    async generateUrlForRecordId(recordId) {
        return this[NavigationMixin.GenerateUrl]({
            type: "standard__recordPage",
            attributes: {
                recordId: recordId,
                actionName: "view"
            }
        });
    }
}