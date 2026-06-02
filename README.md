# Intune Bulk Endpoint Purge Utility

## Description
The **Intune Bulk Endpoint Purge Utility** is an enterprise-grade GUI tool designed to streamline the secure and scalable removal of devices from Microsoft Intune. Utilizing the Microsoft Graph API, this utility securely facilitates bulk device deletions directly from an uploaded CSV file.

Tailored for advanced endpoint management, this project features an immutable, time-stamped CSV audit log generation mechanism, ensuring clear visibility into all purged, skipped, and failed device transactions.

## Features
- **GUI Interface:** A sleek and intuitive Windows Forms UI to easily input your Entra credentials, upload your target file, and track real-time visual feedback via progress bars and active log consoles.
- **Automated Logging:** Emits time-stamped, immutable audit records to a structured `\Reports` directory immediately upon task completion.
- **CSV Import Validation:** Safely checks that target CSV files are structured correctly (e.g. `DeviceName` header in A1) before granting execution capability.
- **Error Scrubber Engine:** Sophisticated exception handling safely flags missing targets or permission denials (like `Forbidden` or `NotFound`) inside the audit log without crashing the application pipeline.

## Prerequisites
Before running the utility, ensure the executing environment meets the following baseline requirements:
- **Microsoft.Graph PowerShell Module:** The system must have the Microsoft.Graph modules installed (the utility will attempt to auto-install missing dependencies upon launch).
- **Entra App Registration (Optional for Quick Start):** You can use the default Native MS Graph CLI ID provided in the GUI for a "Quick Start" capability without needing to configure a custom Azure App Registration. If using your own:
  - Ensure the App Registration has been granted the `DeviceManagementManagedDevices.ReadWrite.All` API permission.
  - Make sure admin consent has been granted for this permission.
- **Privileged Identity Management (PIM):** Ensure you have the proper active role/elevation (if applicable) before launching the execution phase.

## How to Use
1. **Clone the Repository:** Download the project files and keep the files together in an accessible directory.
2. **Prepare Target Manifest:** Create a `.csv` file. Ensure that the header in cell **A1** is exactly named `DeviceName`. List all target hostnames directly underneath this column.
3. **Run the Script:** Right-click the `Launch-Utility.cmd` bootstrapper and select **'Run as Administrator'**.
4. **Input Authentication IDs:** Fill in the **Entra Tenant ID**. The **App Registration Client ID** is pre-filled with the default Native MS Graph CLI ID for a Quick Start, but can be replaced if using a custom registration.
5. **Import CSV:** Click the **Browse...** button to select your target manifest CSV file.
6. **Execute:** Click **EXECUTE BULK REMOVAL** to initiate the sequence. You will be prompted with a final authorization challenge before deletion begins.
7. **Review Log:** Once completed, a prompt will detail your processing metrics. Navigate to the automatically generated `\Reports` subfolder to review the detailed outcome CSV.