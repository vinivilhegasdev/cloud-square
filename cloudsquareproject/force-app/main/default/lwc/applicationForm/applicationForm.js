import { LightningElement } from 'lwc';
import submitApplication from '@salesforce/apex/ApplicationFormController.submitApplication';

const REQUIRED_FIELDS = [
    'companyName',
    'federalTaxId',
    'firstName',
    'lastName',
    'email',
    'phone'
];

export default class ApplicationForm extends LightningElement {
    companyName = '';
    federalTaxId = '';
    firstName = '';
    lastName = '';
    email = '';
    phone = '';
    annualRevenue;

    isLoading = false;
    submitted = false;
    showSuccess = false;
    showError = false;
    successMessage = '';
    errorMessage = '';

    handleChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value;
    }

    validateFields() {
        let isValid = true;

        this.template.querySelectorAll('lightning-input').forEach((input) => {
            if (REQUIRED_FIELDS.includes(input.dataset.field)) {
                if (!input.checkValidity()) {
                    input.reportValidity();
                    isValid = false;
                }
            }
        });

        return isValid;
    }

    async handleSubmit() {
        this.showSuccess = false;
        this.showError = false;

        if (!this.validateFields()) {
            return;
        }

        this.isLoading = true;

        const input = {
            companyName: this.companyName,
            federalTaxId: this.federalTaxId,
            firstName: this.firstName,
            lastName: this.lastName,
            email: this.email,
            phone: this.phone,
            annualRevenue: this.annualRevenue ? Number(this.annualRevenue) : null
        };

        try {
            const result = await submitApplication({ input });

            if (result.success) {
                this.successMessage = `Application submitted successfully! Created a ${result.recordType} (Id: ${result.recordId}).`;
                this.showSuccess = true;
                this.submitted = true;
            } else {
                this.errorMessage = result.message || 'Something went wrong. Please try again.';
                this.showError = true;
            }
        } catch (error) {
            this.errorMessage = (error?.body?.message) || 'Unexpected error submitting the application.';
            this.showError = true;
        } finally {
            this.isLoading = false;
        }
    }
}