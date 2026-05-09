import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/screens/login_screen.dart';
import '../quiz/quiz_screens.dart';
import '../quiz/join_live_quiz_screen.dart';

// ── Shell ─────────────────────────────────────────────────────────────────────
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});
  @override
  State<StudentShell> createState() => _StudentShellState();
}
class _StudentShellState extends State<StudentShell> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      StudentDashboard(onTabChange: (i) => setState(() => _index = i)),
      const StudentClassesPage(),
      const StudentMaterialPage(),
      const StudentQuizPage(),
      StudentProfilePage(onTabChange: (i) => setState(() => _index = i)),
    ];
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: StudentTabBar(currentIndex: _index, onTap: (i) => setState(() => _index = i)),
    );
  }
}

// ── Dashboard ─────────────────────────────────────────────────────────────────
class StudentDashboard extends StatelessWidget {
  final void Function(int)? onTabChange;
  const StudentDashboard({super.key, required this.onTabChange});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser!;
    final classes = state.myClasses;
    final tests = state.allTests;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_getGreeting(), style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
              Text(user.name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            ]),
            GradientAvatar(initials: user.avatarInitials, radius: 22, fontSize: 16),
          ]).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 20),
          Row(children: [
            StatCard(icon: Symbols.menu_book, value: '${classes.length}', label: 'Classes', iconColor: AppColors.primary),
            const SizedBox(width: 12),
            StatCard(icon: Symbols.assignment, value: '${tests.length}', label: 'Tests Due', iconColor: AppColors.warning),
            const SizedBox(width: 12),
            StatCard(icon: Symbols.payments, value: 'Paid', label: 'Fee', iconColor: AppColors.success),
          ]).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinLiveQuizScreen())),
            child: Container(
              height: 90, padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(11)),
                    child: Row(children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('LIVE NOW', style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  Text('Physics Quiz', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  Text('Mr. Sharma • 24 students joined', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                ]),
                Container(
                  width: 72, height: 38,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Text('Join', style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0),
          const SizedBox(height: 24),
          SectionHeader(title: 'My Classes', action: 'See All'),
          const SizedBox(height: 12),
          if (classes.isEmpty)
            Center(child: Text('Join a class to get started!', style: GoogleFonts.poppins(color: AppColors.textSecondary)))
          else
            ...classes.take(2).toList().asMap().entries.map((e) {
              final cls = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ClassListTile(
                  icon: _sIcon(cls.subject), iconColor: _sColor(e.key),
                  name: cls.name, subtitle: '${cls.teacherName} • ${cls.studentCount} students',
                ).animate().fadeIn(delay: (300 + e.key * 80).ms).slideX(begin: 0.1, end: 0),
              );
            }),
          const SizedBox(height: 24),
          SectionHeader(title: 'Upcoming Tests', action: 'See All'),
          const SizedBox(height: 12),
          if (tests.isEmpty)
            Text('No upcoming tests', style: GoogleFonts.poppins(color: AppColors.textSecondary))
          else
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TestAttemptScreen(test: tests.first))),
              child: Container(
                height: 72, padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.warning.withOpacity(0.2))),
                child: Row(children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Symbols.quiz, color: AppColors.warning, size: 22)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(tests.first.title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('Tomorrow 10:00 AM  •  ${tests.first.durationMinutes} mins', style: GoogleFonts.poppins(color: AppColors.warning, fontSize: 12)),
                  ])),
                  const Icon(Symbols.chevron_right, color: AppColors.textMuted, size: 20),
                ]),
              ).animate().fadeIn(delay: 450.ms),
            ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌤';
    if (hour < 17) return 'Good Afternoon ☀️';
    if (hour < 21) return 'Good Evening 🌆';
    return 'Good Night 🌙';
  }

  IconData _sIcon(String s) {
    if (s.toLowerCase().contains('physics')) return Symbols.science;
    if (s.toLowerCase().contains('math')) return Symbols.calculate;
    if (s.toLowerCase().contains('hist')) return Symbols.history_edu;
    return Symbols.school;
  }
  Color _sColor(int i) {
    const c = [AppColors.primary, AppColors.warning, AppColors.success, AppColors.accent];
    return c[i % c.length];
  }
}

// ── Classes Page ──────────────────────────────────────────────────────────────
class StudentClassesPage extends StatefulWidget {
  const StudentClassesPage({super.key});
  @override State<StudentClassesPage> createState() => _StudentClassesPageState();
}
class _StudentClassesPageState extends State<StudentClassesPage> {
  void _showJoinSheet() => showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (_) => const _JoinClassSheet());
  @override
  Widget build(BuildContext context) {
    final classes = context.watch<AppState>().myClasses;
    return SafeArea(bottom: false, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(24,12,24,0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('My Classes', style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
        GestureDetector(onTap: _showJoinSheet, child: Container(height:38, padding: const EdgeInsets.symmetric(horizontal:12), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [const Icon(Symbols.add,color:Colors.white,size:18), const SizedBox(width:6), Text('Join Class', style: GoogleFonts.poppins(color:Colors.white,fontSize:13,fontWeight:FontWeight.w600))]))),
      ])),
      const SizedBox(height:12),
      Expanded(child: classes.isEmpty
        ? Center(child: Column(mainAxisSize:MainAxisSize.min, children:[const Icon(Symbols.menu_book,color:AppColors.textMuted,size:48),const SizedBox(height:12),Text('No classes yet',style:GoogleFonts.poppins(color:AppColors.textSecondary,fontSize:16)),const SizedBox(height:8),Text('Join a class with a code from your teacher',style:GoogleFonts.poppins(color:AppColors.textMuted,fontSize:13),textAlign:TextAlign.center)]))
        : ListView.separated(padding:const EdgeInsets.symmetric(horizontal:24,vertical:8),itemCount:classes.length,separatorBuilder:(_,__)=>const SizedBox(height:10),
            itemBuilder:(_,i){final cls=classes[i];return ClassListTile(icon:_icon(cls.subject),iconColor:_color(i),name:cls.name,subtitle:'${cls.teacherName} • ${cls.studentCount} students').animate().fadeIn(delay:(i*60).ms);})),
    ]));
  }
  IconData _icon(String s){if(s.toLowerCase().contains('physics'))return Symbols.science;if(s.toLowerCase().contains('math'))return Symbols.calculate;if(s.toLowerCase().contains('hist'))return Symbols.history_edu;return Symbols.school;}
  Color _color(int i){const c=[AppColors.primary,AppColors.warning,AppColors.success,AppColors.accent];return c[i%c.length];}
}

// ── Join Class Sheet ──────────────────────────────────────────────────────────
class _JoinClassSheet extends StatefulWidget {
  const _JoinClassSheet();
  @override State<_JoinClassSheet> createState() => _JoinClassSheetState();
}
class _JoinClassSheetState extends State<_JoinClassSheet> {
  final _ctrls = List.generate(6, (_) => TextEditingController());
  final _foci  = List.generate(6, (_) => FocusNode());
  String? _error; bool _loading=false; ClassModel? _preview;
  String get _code => _ctrls.map((c)=>c.text).join().toUpperCase();
  void _onChange(int i,String v){
    if(v.isNotEmpty&&i<5)_foci[i+1].requestFocus();
    if(v.isEmpty&&i>0)_foci[i-1].requestFocus();
    final code=_code;
    setState((){_preview=code.length==6?context.read<AppState>().classForCode(code):null;});
  }
  Future<void> _join() async {
    if(_code.length<6)return;
    setState((){_loading=true;_error=null;});
    final err=await context.read<AppState>().joinClass(_code);
    if(!mounted)return;
    setState((){_loading=false;});
    if(err!=null){setState((){_error=err;});return;}
    Navigator.pop(context);
  }
  @override
  Widget build(BuildContext context){
    return Container(
      margin: EdgeInsets.only(top:MediaQuery.of(context).size.height*0.35),
      decoration:const BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.vertical(top:Radius.circular(32))),
      padding:EdgeInsets.fromLTRB(24,16,24,MediaQuery.of(context).viewInsets.bottom+24),
      child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        Center(child:Container(width:64,height:4,decoration:BoxDecoration(color:AppColors.border,borderRadius:BorderRadius.circular(2)))),
        const SizedBox(height:20),
        Text('Join a Class',style:GoogleFonts.poppins(color:Colors.white,fontSize:22,fontWeight:FontWeight.w700)),
        const SizedBox(height:4),
        Text('Enter the 6-digit code shared by your teacher',style:GoogleFonts.poppins(color:AppColors.textSecondary,fontSize:13)),
        const SizedBox(height:16),
        Row(mainAxisAlignment:MainAxisAlignment.center,children:List.generate(6,(i)=>Container(
          margin:const EdgeInsets.symmetric(horizontal:5),width:44,height:64,
          decoration:BoxDecoration(color:AppColors.surface2,borderRadius:BorderRadius.circular(14),border:Border.all(color:_ctrls[i].text.isNotEmpty?AppColors.primary:AppColors.border,width:2)),
          child:TextField(controller:_ctrls[i],focusNode:_foci[i],maxLength:1,textAlign:TextAlign.center,textCapitalization:TextCapitalization.characters,
            style:GoogleFonts.poppins(color:Colors.white,fontSize:24,fontWeight:FontWeight.w700),
            decoration:const InputDecoration(counterText:'',border:InputBorder.none,contentPadding:EdgeInsets.zero),
            onChanged:(v)=>_onChange(i,v)),
        ))),
        if(_preview!=null)...[const SizedBox(height:10),Container(height:72,padding:const EdgeInsets.symmetric(horizontal:16),
          decoration:BoxDecoration(color:AppColors.surface2,borderRadius:BorderRadius.circular(16),border:Border.all(color:AppColors.primary.withOpacity(0.2))),
          child:Row(children:[Container(width:44,height:44,decoration:BoxDecoration(color:AppColors.primaryLight,borderRadius:BorderRadius.circular(14)),child:const Icon(Symbols.science,color:AppColors.primary,size:22)),
            const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[Text(_preview!.name,style:GoogleFonts.poppins(color:Colors.white,fontSize:14,fontWeight:FontWeight.w600)),Text(_preview!.teacherName,style:GoogleFonts.poppins(color:AppColors.textSecondary,fontSize:12))])),
            const Icon(Symbols.check_circle,color:AppColors.success,size:22)]))],
        if(_error!=null)...[const SizedBox(height:8),Text(_error!,style:GoogleFonts.poppins(color:AppColors.error,fontSize:13))],
        const SizedBox(height:14),
        AppButton(label:'Join Class',onTap:_join,loading:_loading),
      ]),
    );
  }
}

// ── Material Page ─────────────────────────────────────────────────────────────
class StudentMaterialPage extends StatelessWidget {
  const StudentMaterialPage({super.key});
  static const _files=[(Symbols.picture_as_pdf,AppColors.accent,'Chapter 4 - Motion Notes','Physics  •  2.4 MB  •  PDF'),(Symbols.description,AppColors.primary,'Algebra Formula Sheet','Maths  •  1.1 MB  •  PDF'),(Symbols.image,AppColors.success,'History Map - India 1857','History  •  3.8 MB  •  Image'),(Symbols.picture_as_pdf,AppColors.warning,'Maths Practice Paper Set 2','Maths  •  5.2 MB  •  PDF')];
  @override
  Widget build(BuildContext context){
    return SafeArea(bottom:false,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Padding(padding:const EdgeInsets.fromLTRB(24,12,24,0),child:Text('Study Material',style:GoogleFonts.poppins(color:Colors.white,fontSize:22,fontWeight:FontWeight.w700))),
      const SizedBox(height:16),
      Padding(padding:const EdgeInsets.symmetric(horizontal:24),child:Row(children:['All','PDFs','Notes'].asMap().entries.map((e)=>Padding(padding:const EdgeInsets.only(right:8),child:Container(height:36,width:80,decoration:BoxDecoration(color:e.key==0?AppColors.primary:AppColors.surface,borderRadius:BorderRadius.circular(10)),alignment:Alignment.center,child:Text(e.value,style:GoogleFonts.poppins(color:e.key==0?Colors.white:AppColors.textSecondary,fontSize:13,fontWeight:FontWeight.w500))))).toList())),
      const SizedBox(height:12),
      Expanded(child:ListView.separated(padding:const EdgeInsets.symmetric(horizontal:24,vertical:4),itemCount:_files.length,separatorBuilder:(_,__)=>const SizedBox(height:10),
        itemBuilder:(_,i){final f=_files[i];return Container(height:80,padding:const EdgeInsets.symmetric(horizontal:16),decoration:BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.circular(16)),
          child:Row(children:[Container(width:48,height:48,decoration:BoxDecoration(color:f.$2.withOpacity(0.13),borderRadius:BorderRadius.circular(14)),child:Icon(f.$1,color:f.$2,size:24)),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[Text(f.$3,style:GoogleFonts.poppins(color:Colors.white,fontSize:14,fontWeight:FontWeight.w600)),Text(f.$4,style:GoogleFonts.poppins(color:AppColors.textSecondary,fontSize:12))])),const Icon(Symbols.download,color:AppColors.primary,size:22)])).animate().fadeIn(delay:(i*60).ms);})),
    ]));
  }
}

// ── Quiz Page ─────────────────────────────────────────────────────────────────
class StudentQuizPage extends StatelessWidget {
  const StudentQuizPage({super.key});
  @override
  Widget build(BuildContext context){
    final tests=context.watch<AppState>().allTests;
    return SafeArea(bottom:false,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Padding(padding:const EdgeInsets.fromLTRB(24,12,24,0),child:Text('My Tests',style:GoogleFonts.poppins(color:Colors.white,fontSize:22,fontWeight:FontWeight.w700))),
      const SizedBox(height:12),
      Padding(padding:const EdgeInsets.symmetric(horizontal:24),child:GestureDetector(onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const JoinLiveQuizScreen())),
        child:Container(height:62,padding:const EdgeInsets.symmetric(horizontal:16),decoration:BoxDecoration(gradient:const LinearGradient(colors:[AppColors.primary,AppColors.accent],begin:Alignment.centerLeft,end:Alignment.centerRight),borderRadius:BorderRadius.circular(16)),
          child:Row(children:[Container(width:34,height:34,decoration:BoxDecoration(color:Colors.white.withOpacity(0.2),shape:BoxShape.circle),child:const Icon(Symbols.wifi_tethering,color:Colors.white,size:18)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[Text('Join Live Quiz',style:GoogleFonts.poppins(color:Colors.white,fontSize:14,fontWeight:FontWeight.w700)),Text('Enter PIN from your teacher',style:GoogleFonts.poppins(color:Colors.white70,fontSize:11))])),const Icon(Symbols.arrow_forward,color:Colors.white,size:18)])))).animate().fadeIn(duration:400.ms),
      const SizedBox(height:12),
      Padding(padding:const EdgeInsets.symmetric(horizontal:24),child:Row(children:[Container(height:36,width:100,decoration:BoxDecoration(color:AppColors.warning,borderRadius:BorderRadius.circular(10)),alignment:Alignment.center,child:Text('Upcoming',style:GoogleFonts.poppins(color:AppColors.bg,fontSize:12,fontWeight:FontWeight.w600))),const SizedBox(width:8),Container(height:36,width:80,decoration:BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.circular(10)),alignment:Alignment.center,child:Text('Done',style:GoogleFonts.poppins(color:AppColors.textSecondary,fontSize:12)))])),
      const SizedBox(height:12),
      Expanded(child:tests.isEmpty?Center(child:Text('No tests scheduled',style:GoogleFonts.poppins(color:AppColors.textSecondary))):ListView.separated(padding:const EdgeInsets.symmetric(horizontal:24,vertical:4),itemCount:tests.length,separatorBuilder:(_,__)=>const SizedBox(height:12),itemBuilder:(_,i)=>_TestCard(test:tests[i],index:i))),
    ]));
  }
}
class _TestCard extends StatelessWidget {
  final TestModel test; final int index;
  const _TestCard({required this.test,required this.index});
  @override
  Widget build(BuildContext context){
    return GestureDetector(onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>TestAttemptScreen(test:test))),
      child:Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.circular(18),border:Border.all(color:AppColors.warning.withOpacity(0.2))),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Expanded(child:Text(test.title,style:GoogleFonts.poppins(color:Colors.white,fontSize:15,fontWeight:FontWeight.w600))),Container(height:24,padding:const EdgeInsets.symmetric(horizontal:8),decoration:BoxDecoration(color:AppColors.warningLight,borderRadius:BorderRadius.circular(8)),alignment:Alignment.center,child:Text('Tomorrow',style:GoogleFonts.poppins(color:AppColors.warning,fontSize:10,fontWeight:FontWeight.w600)))]),const SizedBox(height:10),Row(children:[const Icon(Symbols.schedule,color:AppColors.textSecondary,size:14),const SizedBox(width:4),Text('${test.durationMinutes} mins',style:GoogleFonts.poppins(color:AppColors.textSecondary,fontSize:12)),const SizedBox(width:16),const Icon(Symbols.help,color:AppColors.textSecondary,size:14),const SizedBox(width:4),Text('${test.questionCount} Questions',style:GoogleFonts.poppins(color:AppColors.textSecondary,fontSize:12))])])).animate().fadeIn(delay:(index*60).ms));
  }
}

// ── Profile Page ──────────────────────────────────────────────────────────────
class StudentProfilePage extends StatelessWidget {
  final void Function(int)? onTabChange;
  const StudentProfilePage({super.key,this.onTabChange});
  @override
  Widget build(BuildContext context){
    final state=context.watch<AppState>();final user=state.currentUser!;final attempts=state.myAttempts;
    return SafeArea(bottom:false,child:SingleChildScrollView(child:Column(children:[
      Container(height:260,width:double.infinity,decoration:const BoxDecoration(gradient:LinearGradient(colors:[Color(0xFF1C1240),AppColors.bg],begin:Alignment.topCenter,end:Alignment.bottomCenter)),
        child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[const SizedBox(height:50),Stack(alignment:Alignment.bottomCenter,children:[GradientAvatar(initials:user.avatarInitials,radius:40,fontSize:28),Positioned(bottom:0,child:Container(height:22,width:48,decoration:BoxDecoration(color:AppColors.success,borderRadius:BorderRadius.circular(11)),alignment:Alignment.center,child:Text('PRO',style:GoogleFonts.poppins(color:Colors.white,fontSize:10,fontWeight:FontWeight.w700))))]),const SizedBox(height:12),Text(user.name,style:GoogleFonts.poppins(color:Colors.white,fontSize:20,fontWeight:FontWeight.w700)),Text(user.email,style:GoogleFonts.poppins(color:AppColors.textSecondary,fontSize:13))])),
      Padding(padding:const EdgeInsets.symmetric(horizontal:24),child:Column(children:[
        Container(height:72,decoration:BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.circular(16)),child:Row(children:[_si('3','Classes',AppColors.primary),Container(width:1,height:40,color:AppColors.border),_si('${attempts.length}','Tests Done',AppColors.warning),Container(width:1,height:40,color:AppColors.border),_si('84%','Avg Score',AppColors.success)])),
        const SizedBox(height:16),
        MenuRow(icon:Symbols.person,iconColor:AppColors.primary,label:'Edit Profile'),const SizedBox(height:10),
        MenuRow(icon:Symbols.notifications,iconColor:AppColors.warning,label:'Notifications'),const SizedBox(height:10),
        MenuRow(icon:Symbols.lock,iconColor:AppColors.success,label:'Change Password'),const SizedBox(height:10),
        MenuRow(icon:Symbols.help,iconColor:AppColors.textSecondary,label:'Help & Support'),
        const SizedBox(height:20),
        SectionHeader(title:'My Quiz Results',action:'View All',onAction:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const QuizResultsListScreen()))),
        const SizedBox(height:12),
        if(attempts.isEmpty)Text('No quiz attempts yet',style:GoogleFonts.poppins(color:AppColors.textSecondary))
        else ...attempts.take(2).map((a)=>Padding(padding:const EdgeInsets.only(bottom:10),child:_QRCard(attempt:a))),
        const SizedBox(height:20),
        GestureDetector(onTap:(){context.read<AppState>().logout();Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder:(_)=>const LoginScreen()),(_)=>false);},
          child:Container(height:52,padding:const EdgeInsets.symmetric(horizontal:16),decoration:BoxDecoration(color:AppColors.errorLight,borderRadius:BorderRadius.circular(14),border:Border.all(color:AppColors.error.withOpacity(0.2))),
            child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[const Icon(Symbols.logout,color:AppColors.error,size:20),const SizedBox(width:10),Text('Logout',style:GoogleFonts.poppins(color:AppColors.error,fontSize:15,fontWeight:FontWeight.w600))]))),
        const SizedBox(height:16),
      ])),
    ])));
  }
  Widget _si(String v,String l,Color c)=>Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(v,style:GoogleFonts.poppins(color:c,fontSize:20,fontWeight:FontWeight.w700)),Text(l,style:GoogleFonts.poppins(color:AppColors.textSecondary,fontSize:11))]));
}
class _QRCard extends StatelessWidget {
  final QuizAttempt attempt;const _QRCard({required this.attempt});
  @override
  Widget build(BuildContext context){
    return Container(height:68,padding:const EdgeInsets.symmetric(horizontal:14),decoration:BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.circular(14)),
      child:Row(children:[Container(width:44,height:44,decoration:BoxDecoration(color:AppColors.successLight,borderRadius:BorderRadius.circular(12)),alignment:Alignment.center,child:Text('A',style:GoogleFonts.poppins(color:AppColors.success,fontSize:18,fontWeight:FontWeight.w700))),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[Text(attempt.testTitle,style:GoogleFonts.poppins(color:Colors.white,fontSize:13,fontWeight:FontWeight.w600)),Text('Rank #${attempt.rank} of ${attempt.totalParticipants}',style:GoogleFonts.poppins(color:AppColors.textSecondary,fontSize:11))])),Text('84%',style:GoogleFonts.poppins(color:AppColors.success,fontSize:15,fontWeight:FontWeight.w700))]));
  }
}
