// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:socialmedia/utils/colors.dart';

// class TermsAndConditionsScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Terms & Conditions', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText),),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(16.w),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Terms & Conditions',
//               style: GoogleFonts.montserrat(
//                 fontSize: 20.sp,
//                 fontWeight: FontWeight.bold,
//                 color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText
//               ),
//             ),
//             SizedBox(height: 16.h),
//             Text(
//               'Acceptance of Terms\nThe services that BondBridge provides to all users are subject to the following Terms of Use ("TOU"). BondBridge reserves the right to update and modify the TOU at any time without notice. The most current version of the TOU can be reviewed by clicking on the "Terms of Use" hypertext link located at the bottom of our Web pages. When we make updates to the TOU, BondBridge will update the date at the top of this page. By using the website after a new version of the TOU has been posted, you agree to the terms of such new version.\n\nDescription of Services\nThrough its network of Web properties, BondBridge provides you with access to a variety of resources, including applications, download areas, communication forums and product information (collectively "Services"). The Services, including any updates, enhancements, new features, and/or the addition of any new Web properties, are subject to this TOU.\n\nPersonal and Non-Commercial Use Limitation\nUnless otherwise specified, the Services are for your personal and non-commercial use. You may not modify, copy, distribute, transmit, display, perform, reproduce, publish, license, create derivative works from, transfer, or sell any information, software, products or services obtained from the Services.\n\nPrivacy and Protection of Personal Information\nSee the Privacy Statement disclosures relating to the collection and use of your personal data.\n\nContent\nAll content included in or made available through the Services is the exclusive property of BondBridge or its content suppliers and is protected by applicable intellectual property laws. All rights not expressly granted are reserved and retained by BondBridge or its licensors.\n\nSoftware\nAny software available through the Services is copyrighted by BondBridge and/or its suppliers. Use of the Software is governed by the end user license agreement. Unauthorized reproduction or redistribution is prohibited by law and may result in legal penalties.\n\nRestricted Rights Legend\nSoftware downloaded for or on behalf of the U.S. Government is provided with Restricted Rights as defined in applicable federal regulations. Manufacturer is BondBridge Corporation, One BondBridge Way, Redmond, WA 98052-6399.\n\nDocuments\nPermission is granted to use Documents from the Services for non-commercial or personal use under specific conditions. Educational institutions may use them for classroom distribution. Any other use requires written permission.\n\nThese permissions do not include website design or layout elements, which may not be copied or imitated without express permission.\n\nRepresentations and Warranties\nSoftware and tools are provided "as is" without warranties except as specified in the license agreement. BondBridge disclaims all other warranties including merchantability and fitness for a particular purpose.\n\nLimitation of Liability\nBondBridge is not liable for any damages resulting from the use or inability to use the Services, including software, documents, or data.\n\nMember Account, Password, and Security\nYou are responsible for maintaining the confidentiality of your account credentials and all activities that occur under your account. Unauthorized use must be reported immediately.\n\nNo Unlawful or Prohibited Use\nYou agree not to use the Services for unlawful purposes or in ways that impair, disable, or damage the Services or interfere with others\' use.\n\nUse of Services\nThe Services may include communication tools. You agree to use them only to post and share appropriate, lawful content. Examples of prohibited actions include spamming, harassment, uploading viruses, and violating others\' rights.\n\nNo spamming or chain messages\nNo harassment or privacy violations\nNo posting inappropriate or unlawful content\nNo distribution of protected content without rights\nNo uploading of harmful software\nNo unauthorized advertising\nNo downloading of content that cannot be legally shared\nNo deletion of copyright or source information\nNo obstruction of others\' use of services\nNo identity falsification\nNo unlawful activity or violations of conduct codes\nBondBridge may remove content or suspend access at its discretion and is not responsible for content shared by users. Use caution when sharing personal information.\n\nAI Services\nAI Services may not be reverse engineered or used for scraping or training other AI systems. BondBridge monitors inputs and outputs to prevent abuse. Users are responsible for legal compliance and third-party claims related to AI use.\n\nMaterials Provided to BondBridge\nBy submitting content, you grant BondBridge the rights to use it in connection with its Services. No compensation is provided. You must own or have permission to share submitted content, including images.\n\nCopyright Infringement\nTo report copyright violations, follow the procedures under Title 17, U.S. Code, Section 512(c)(2). Non-relevant inquiries will not receive responses.\n\nLinks to Third Party Sites\nLinked third-party websites are not under BondBridge\'s control. BondBridge is not responsible for their content or transmissions. Links are provided for convenience, not endorsement.\n\nUnsolicited Idea Submission Policy\nBondBridge does not accept unsolicited ideas. If submitted, such materials are not treated as confidential or proprietary. This policy prevents disputes over similar ideas developed by BondBridge.',
//               style: GoogleFonts.montserrat(
//                 fontSize: 14.sp,
//                 color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                
//               ),
//               textAlign: TextAlign.justify,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialmedia/utils/colors.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Terms & Conditions',
          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms & Conditions',
              style: GoogleFonts.montserrat(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText),
            ),
            SizedBox(height: 16.h),
            RichText(
              textAlign: TextAlign.justify,
              text: TextSpan(
                style: GoogleFonts.montserrat(
                  fontSize: 14.sp,
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                ),
                children: [
                  _buildHeading('Acceptance of Terms'),
                  TextSpan(text: 'The services that BondBridge provides to all users are subject to the following Terms of Use ("TOU"). BondBridge reserves the right to update and modify the TOU at any time without notice. The most current version of the TOU can be reviewed by clicking on the "Terms of Use" hypertext link located at the bottom of our Web pages. When we make updates to the TOU, BondBridge will update the date at the top of this page. By using the website after a new version of the TOU has been posted, you agree to the terms of such new version.\n\n'),
                  _buildHeading('Description of Services'),
                  TextSpan(text: 'Through its network of Web properties, BondBridge provides you with access to a variety of resources, including applications, download areas, communication forums and product information (collectively "Services"). The Services, including any updates, enhancements, new features, and/or the addition of any new Web properties, are subject to this TOU.\n\n'),
                  _buildHeading('Personal and Non-Commercial Use Limitation'),
                  TextSpan(text: 'Unless otherwise specified, the Services are for your personal and non-commercial use. You may not modify, copy, distribute, transmit, display, perform, reproduce, publish, license, create derivative works from, transfer, or sell any information, software, products or services obtained from the Services.\n\n'),
                  _buildHeading('Privacy and Protection of Personal Information'),
                  TextSpan(text: 'See the Privacy Statement disclosures relating to the collection and use of your personal data.\n\n'),
                  _buildHeading('Content'),
                  TextSpan(text: 'All content included in or made available through the Services is the exclusive property of BondBridge or its content suppliers and is protected by applicable intellectual property laws. All rights not expressly granted are reserved and retained by BondBridge or its licensors.\n\n'),
                  _buildHeading('Software'),
                  TextSpan(text: 'Any software available through the Services is copyrighted by BondBridge and/or its suppliers. Use of the Software is governed by the end user license agreement. Unauthorized reproduction or redistribution is prohibited by law and may result in legal penalties.\n\n'),
                  _buildHeading('Restricted Rights Legend'),
                  TextSpan(text: 'Software downloaded for or on behalf of the U.S. Government is provided with Restricted Rights as defined in applicable federal regulations. Manufacturer is BondBridge Corporation, One BondBridge Way, Redmond, WA 98052-6399.\n\n'),
                  _buildHeading('Documents'),
                  TextSpan(text: 'Permission is granted to use Documents from the Services for non-commercial or personal use under specific conditions. Educational institutions may use them for classroom distribution. Any other use requires written permission.\n\nThese permissions do not include website design or layout elements, which may not be copied or imitated without express permission.\n\n'),
                  _buildHeading('Representations and Warranties'),
                  TextSpan(text: 'Software and tools are provided "as is" without warranties except as specified in the license agreement. BondBridge disclaims all other warranties including merchantability and fitness for a particular purpose.\n\n'),
                  _buildHeading('Limitation of Liability'),
                  TextSpan(text: 'BondBridge is not liable for any damages resulting from the use or inability to use the Services, including software, documents, or data.\n\n'),
                  _buildHeading('Member Account, Password, and Security'),
                  TextSpan(text: 'You are responsible for maintaining the confidentiality of your account credentials and all activities that occur under your account. Unauthorized use must be reported immediately.\n\n'),
                  _buildHeading('No Unlawful or Prohibited Use'),
                  TextSpan(text: 'You agree not to use the Services for unlawful purposes or in ways that impair, disable, or damage the Services or interfere with others\' use.\n\n'),
                  _buildHeading('Use of Services'),
                  TextSpan(text: 'The Services may include communication tools. You agree to use them only to post and share appropriate, lawful content. Examples of prohibited actions include spamming, harassment, uploading viruses, and violating others\' rights.\n\n'),
                  _buildHeading('No spamming or chain messages'),
                  TextSpan(text: 'No harassment or privacy violations\nNo posting inappropriate or unlawful content\nNo distribution of protected content without rights\nNo uploading of harmful software\nNo unauthorized advertising\nNo downloading of content that cannot be legally shared\nNo deletion of copyright or source information\nNo obstruction of others\' use of services\nNo identity falsification\nNo unlawful activity or violations of conduct codes\nBondBridge may remove content or suspend access at its discretion and is not responsible for content shared by users. Use caution when sharing personal information.\n\n'),
                  _buildHeading('AI Services'),
                  TextSpan(text: 'AI Services may not be reverse engineered or used for scraping or training other AI systems. BondBridge monitors inputs and outputs to prevent abuse. Users are responsible for legal compliance and third-party claims related to AI use.\n\n'),
                  _buildHeading('Materials Provided to BondBridge'),
                  TextSpan(text: 'By submitting content, you grant BondBridge the rights to use it in connection with its Services. No compensation is provided. You must own or have permission to share submitted content, including images.\n\n'),
                  _buildHeading('Copyright Infringement'),
                  TextSpan(text: 'To report copyright violations, follow the procedures under Title 17, U.S. Code, Section 512(c)(2). Non-relevant inquiries will not receive responses.\n\n'),
                  _buildHeading('Links to Third Party Sites'),
                  TextSpan(text: 'Linked third-party websites are not under BondBridge\'s control. BondBridge is not responsible for their content or transmissions. Links are provided for convenience, not endorsement.\n\n'),
                  _buildHeading('Unsolicited Idea Submission Policy'),
                  TextSpan(text: 'BondBridge does not accept unsolicited ideas. If submitted, such materials are not treated as confidential or proprietary. This policy prevents disputes over similar ideas developed by BondBridge.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextSpan _buildHeading(String text) {
    return TextSpan(
      text: '$text\n',
      style: GoogleFonts.montserrat(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
