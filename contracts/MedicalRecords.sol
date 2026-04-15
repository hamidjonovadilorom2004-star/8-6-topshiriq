// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MedicalRecords {
    struct Record {
        string diagnosis;
        string treatment;
        uint256 timestamp;
        address doctor;
    }

    struct Patient {
        bool exists;
        Record[] records;
        mapping(address => bool) authorizedDoctors;
    }

    mapping(address => Patient) private patients;
    mapping(bytes32 => bool) public authenticMedicines;
    
    // Access Log
    struct AccessLog {
        address accessor;
        uint256 timestamp;
        string action;
    }
    mapping(address => AccessLog[]) private logs;

    event RecordAdded(address indexed patient, address indexed doctor, string diagnosis);
    event AccessGranted(address indexed patient, address indexed doctor);
    event AccessRevoked(address indexed patient, address indexed doctor);
    event MedicineVerified(bytes32 indexed medicineId, bool isValid);

    modifier onlyPatient() {
        require(patients[msg.sender].exists, "Not a registered patient");
        _;
    }

    modifier canAccess(address _patient) {
        require(
            msg.sender == _patient || patients[_patient].authorizedDoctors[msg.sender],
            "Not authorized to view records"
        );
        _;
    }

    constructor() {
        // Pre-fill some medicines for demo
        authenticMedicines[keccak256(abi.encodePacked("ASPIRIN123"))] = true;
        authenticMedicines[keccak256(abi.encodePacked("PARACETAMOL456"))] = true;
    }

    function registerPatient() public {
        require(!patients[msg.sender].exists, "Already registered");
        patients[msg.sender].exists = true;
    }

    function grantAccess(address _doctor) public {
        patients[msg.sender].authorizedDoctors[_doctor] = true;
        emit AccessGranted(msg.sender, _doctor);
    }

    function revokeAccess(address _doctor) public {
        patients[msg.sender].authorizedDoctors[_doctor] = false;
        emit AccessRevoked(msg.sender, _doctor);
    }

    function addRecord(address _patient, string memory _diagnosis, string memory _treatment) public {
        require(patients[_patient].authorizedDoctors[msg.sender], "Not an authorized doctor");
        
        patients[_patient].records.push(Record({
            diagnosis: _diagnosis,
            treatment: _treatment,
            timestamp: block.timestamp,
            doctor: msg.sender
        }));

        logs[_patient].push(AccessLog({
            accessor: msg.sender,
            timestamp: block.timestamp,
            action: "Added medical record"
        }));

        emit RecordAdded(_patient, msg.sender, _diagnosis);
    }

    function getPatientRecords(address _patient) public view canAccess(_patient) returns (Record[] memory) {
        return patients[_patient].records;
    }

    function getAccessLogs(address _patient) public view returns (AccessLog[] memory) {
        require(msg.sender == _patient, "Only patient can view logs");
        return logs[_patient];
    }

    function verifyMedicine(string memory _medicineName) public returns (bool) {
        bytes32 medicineId = keccak256(abi.encodePacked(_medicineName));
        bool isValid = authenticMedicines[medicineId];
        emit MedicineVerified(medicineId, isValid);
        return isValid;
    }
    
    function isDoctorAuthorized(address _patient, address _doctor) public view returns (bool) {
        return patients[_patient].authorizedDoctors[_doctor];
    }
}
