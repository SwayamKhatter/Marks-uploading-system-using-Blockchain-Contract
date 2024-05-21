// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

contract project {
    address owner;
    mapping(string => mapping(address => bool)) subjectToTeacher;
    mapping(address => Teacher) teachers;
    mapping(address => string[]) subjectArray;
    mapping(address => mapping(string => Student)) students;
    mapping(address => address[]) mentees;
    mapping(address => address[]) panels;

    constructor() {
        owner = msg.sender;
        collegeAddress = msg.sender;

    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "NOT ACCESSIBLE BY YOU..YOU ARE NOT THE OWNER!!!!!"
        );
        _;
    }

    struct Teacher {
        address teacherAddress;
        mapping(string => bool) teachesSubject;
    }
    //strcutre to store students details
    struct Student {
        uint256 marks;
        string subjectId;
        address updatedby;
        bool hasMarks;
    }
    event marksAlert(string message);

    function addTeacher(string[] memory subjectCode, address teacher)
        public
        onlyOwner
    {
        teachers[teacher].teacherAddress = teacher;
        for (uint256 i = 0; i < subjectCode.length; i++) {
            teachers[teacher].teachesSubject[subjectCode[i]] = true;

            subjectToTeacher[subjectCode[i]][teacher] = true;
        }
        subjectArray[teacher] = subjectCode;
    }

    function viewTeacherSubjects(address teacher)
        public
        view
        returns (string[] memory)
    {
        require(
            teachers[teacher].teacherAddress == teacher,
            "Teacher not registered"
        );
        require(subjectArray[teacher].length != 0, "No subjects Assigned");
        return subjectArray[teacher];
    }

    function mentormentees(address mentor, address[] memory mentees1)
        public
        onlyOwner
    {
        //panelist is panel teacher mentor is personal assigned teacher of the student
        mentees[mentor] = mentees1;
    }

    function panelpanelist(address panelist, address[] memory panelstudents)
        public
        onlyOwner
    {
        //panelist is panel teacher mentor is personal assigned teacher of the student
        panels[panelist] = panelstudents;
    }

    ///
    function PanelMarks(uint256 markss, address student) public {
        address paneladdress;
        // Check if the panel teacher is assigned to the student
        bool isPanelTeacher = false;
        address[] memory panelStudents = panels[msg.sender];
        for (uint256 i = 0; i < panelStudents.length; i++) {
            if (panelStudents[i] == student) {
                isPanelTeacher = true;
                break;
            }
        }
        require(
            isPanelTeacher,
            "You are not the panel teacher assigned to this student"
        );
        if (students[student]["INT301"].hasMarks == false && markss < 30) {
            students[student]["INT301"].hasMarks = true;
            emit marksAlert(
                "ALERT!!! You have  entered less than 30 marks for this student recheck"
            );
        } else if (
            students[student]["INT301"].hasMarks == true && markss < 30
        ) {
            students[student]["INT301"].marks =
                students[student]["INT301"].marks +
                markss;
        } else {
            students[student]["INT301"].marks =
                students[student]["INT301"].marks +
                markss;
            paneladdress = msg.sender;
        }
    }

    function mentorMarks(uint256 markss, address student) public {
        require(
            mentees[msg.sender].length > 0,
            "You are not assigned as a mentor to any student."
        );
        bool isMentor = false;
        for (uint256 i = 0; i < mentees[msg.sender].length; i++) {
            if (mentees[msg.sender][i] == student) {
                isMentor = true;
                break;
            }
        }
        require(isMentor, "You are not the mentor of this student.");
        students[student]["INT301"].marks =
            students[student]["INT301"].marks +
            markss;
    }

    function updateMarks(
        address student,
        string memory subjectId1,
        uint256 marks
    ) public {
        require(
            msg.sender == owner || subjectToTeacher[subjectId1][msg.sender],
            "ACCESS NOT GRANTED"
        );

        if (!students[student][subjectId1].hasMarks) {
            students[student][subjectId1].hasMarks = true;
            students[student][subjectId1].updatedby = msg.sender;
        } else {
            require(
                students[student][subjectId1].updatedby == msg.sender,
                "Student marks can only be updated by the teacher who uploaded it for the first time"
            );
        }
        students[student][subjectId1].marks = marks;
        students[student][subjectId1].subjectId = subjectId1;
    }

    function viewMarks(address student, string memory subjectId1)
        public
        view
        returns (uint256)
    {
        require(
            msg.sender == owner ||
                subjectToTeacher[subjectId1][msg.sender] ||
                msg.sender == student,
            "ACCESS DENIED!!!!"
        );
        return students[student][subjectId1].marks;
    }
    struct Certificate {
    address studentAddress;  // Student's Ethereum address
    string metadata;        // Student-specific details as a string
    uint256 issuedAt;        // Timestamp of certificate issuance
  }

  // Mapping to store certificates issued by the college, indexed by certificate ID
  mapping(uint256 => Certificate) public certificates;

  // Mapping to store all certificate IDs issued to a student, indexed by student address
  mapping(address => uint256[]) public studentCertificates;  // Array of certificate IDs

  // College's address (only the college can mint certificates)
  address public collegeAddress;

  // Event emitted when a certificate is minted
  event CertificateMinted(uint256 certificateId, address studentAddress, string metadata);

 

  // Function for the college to mint a certificate for a student
  function mintCertificate(address student, string calldata metadata) public {
    require(msg.sender == collegeAddress, "Only the college can mint certificates");

    uint256 certificateId = generateCertificateId(student, metadata);
    require(certificates[certificateId].studentAddress == address(0), "Certificate already exists");

    certificates[certificateId] = Certificate(student, metadata, block.timestamp);

    studentCertificates[student] = pushCertificateId(studentCertificates[student], certificateId); // Add certificate ID to student's list

    emit CertificateMinted(certificateId, student, metadata);
  }

  // Function for students or verification systems to verify a certificate
  function verifyCertificate(uint256 certificateId, address student, string calldata metadata) public view returns (bool) {
    Certificate memory cert = certificates[certificateId];

    // Check if certificate exists and student addresses and metadata match
    return keccak256(abi.encodePacked(cert.metadata)) == keccak256(abi.encodePacked(metadata)) && cert.studentAddress == student;
  }

  // Function for student to see all their certificate IDs and metadata
  function getStudentCertificates(address studentAddress) private view returns (Certificate[] memory) {
    Certificate[] memory studentCertificatesList = new Certificate[](studentCertificates[studentAddress].length);  // Initialize array with correct size

    // Loop through all certificate IDs of the student
    for (uint256 i = 0; i < studentCertificates[studentAddress].length; i++) {
      uint256 certificateId = studentCertificates[studentAddress][i];
      studentCertificatesList[i] = certificates[certificateId]; // Get certificate details from main mapping
    }

    return studentCertificatesList;
  }

  // Internal function to add a certificate ID to an array (avoiding stack overflow)
  function pushCertificateId(uint256[] memory array, uint256 certificateId) internal pure returns (uint256[] memory) {
    uint256[] memory newArray = new uint256[](array.length + 1);
    for (uint256 i = 0; i < array.length; i++) {
      newArray[i] = array[i];
    }
    newArray[newArray.length - 1] = certificateId;
    return newArray;
  }

  // Function to generate a unique certificate ID based on student and metadata
  function generateCertificateId(address student, string calldata metadata) private pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(student, keccak256(abi.encodePacked(metadata)))));
  }
}
