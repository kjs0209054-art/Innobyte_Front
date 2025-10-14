// Flutter 앱의 기본 패키지들을 가져옵니다
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 앱의 시작점 - 메인 함수
/// Flutter 앱이 실행될 때 가장 먼저 호출되는 함수입니다
void main() {
  runApp(const SamsungNotesApp()); // 삼성 노트 앱 위젯을 실행
}

// ====================================================
// 1. 데이터 모델
// ====================================================
// 앱에서 사용할 데이터의 구조를 정의하는 클래스들입니다

/// 뷰 모드 열거형 - 노트를 어떤 방식으로 보여줄지 선택
/// grid: 격자 형태 (카드처럼 보이는 방식)
/// list: 목록 형태 (한 줄씩 보이는 방식)
/// timeline: 시간순 형태 (날짜별로 그룹화된 방식)
enum ViewMode { grid, list, timeline }

/// 정렬 모드 열거형 - 노트를 어떤 기준으로 정렬할지 선택
/// modifiedDate: 최근 수정한 순서
/// createdDate: 생성한 순서
/// name: 이름 순서
/// starred: 즐겨찾기 우선
enum SortMode { modifiedDate, createdDate, name, starred }

/// 그리기 도구 열거형 - 드로잉 에디터에서 사용할 도구
/// pen: 펜 (일반적인 선)
/// pencil: 연필 (부드러운 선)
/// highlighter: 형광펜 (반투명한 굵은 선)
/// eraser: 지우개
/// lasso: 올가미 (선택 도구)
enum DrawingTool { pen, pencil, highlighter, eraser, lasso }

/// 노트 클래스 - 하나의 노트가 가지는 모든 정보를 담는 클래스
class Note {
  String title; // 노트 제목
  String content; // 노트 내용
  DateTime date; // 마지막 수정 날짜
  DateTime createdDate; // 생성 날짜
  bool isStarred; // 즐겨찾기 여부
  bool isInTrash; // 휴지통에 있는지 여부
  bool isLocked; // 잠금 설정 여부
  bool isHidden; // 숨김 설정 여부
  String? imageUrl; // 노트 썸네일 이미지 (이모지)
  String? folderName; // 속한 폴더 이름
  List<String> tags; // 태그 목록
  List<DrawingStroke> strokes; // 그리기 스트로크 목록

  /// 노트 생성자 - 새로운 노트를 만들 때 필요한 정보를 받습니다
  Note({
    required this.title, // 필수: 제목
    required this.content, // 필수: 내용
    required this.date, // 필수: 날짜
    DateTime? createdDate, // 선택: 생성일 (없으면 date와 동일하게 설정)
    this.isInTrash = false, // 기본값: 휴지통에 없음
    this.isStarred = false, // 기본값: 즐겨찾기 아님
    this.isLocked = false, // 기본값: 잠금 안됨
    this.isHidden = false, // 기본값: 숨김 안됨
    this.imageUrl, // 선택: 이미지 URL
    this.folderName, // 선택: 폴더명
    this.tags = const [], // 기본값: 빈 태그 목록
    this.strokes = const [], // 기본값: 빈 스트로크 목록
  }) : createdDate = createdDate ?? date; // 생성일이 없으면 수정일과 동일하게 설정
}

/// 그리기 스트로크 클래스 - 드로잉 에디터에서 그린 하나의 선을 표현
class DrawingStroke {
  final List<Offset> points; // 선을 구성하는 점들의 좌표 목록
  final Color color; // 선의 색상
  final double width; // 선의 굵기
  final DrawingTool tool; // 사용한 도구 (펜, 연필, 형광펜 등)

  /// 스트로크 생성자 - 새로운 선을 만들 때 필요한 정보
  DrawingStroke({
    required this.points,
    required this.color,
    required this.width,
    required this.tool,
  });
}

/// 폴더 클래스 - 노트를 분류할 수 있는 폴더 정보
class Folder {
  String name; // 폴더 이름
  final int count; // 폴더 안의 노트 개수
  final List<Folder> subfolders; // 하위 폴더 목록
  Color color; // 폴더 색상

  /// 폴더 생성자 - 새로운 폴더를 만들 때 필요한 정보
  Folder({
    required this.name,
    required this.count,
    this.subfolders = const [], // 기본값: 빈 하위 폴더 목록
    this.color = const Color(0xFF678AFB), // 기본값: 파란색
  });
}

// ====================================================
// 2. 메인 애플리케이션 및 상태 관리
// ====================================================

/// 삼성 노트 앱의 최상위 위젯
/// 상태가 변경될 수 있는 위젯 (다크모드/라이트모드 전환 기능)
class SamsungNotesApp extends StatefulWidget {
  const SamsungNotesApp({super.key});

  @override
  State<SamsungNotesApp> createState() => _SamsungNotesAppState();
}

/// 삼성 노트 앱의 상태를 관리하는 클래스
class _SamsungNotesAppState extends State<SamsungNotesApp> {
  // 현재 테마 모드 (라이트 모드가 기본값)
  ThemeMode themeMode = ThemeMode.light;

  /// 테마 전환 함수 (라이트 모드 ↔ 다크 모드)
  void toggleTheme() {
    setState(() {
      // 현재 라이트 모드면 다크 모드로, 다크 모드면 라이트 모드로 변경
      themeMode = themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  /// 앱의 UI를 빌드하는 함수
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Samsung Notes Clone', // 앱 제목
      debugShowCheckedModeBanner: false, // 디버그 배너 숨김
      themeMode: themeMode, // 현재 테마 모드
      // 라이트 테마 설정
      theme: ThemeData(
        primarySwatch: Colors.blueGrey, // 기본 색상
        scaffoldBackgroundColor: const Color(0xFFF0F0F0), // 배경 색상 (밝은 회색)
        brightness: Brightness.light, // 밝은 테마
      ),
      // 다크 테마 설정
      darkTheme: ThemeData(
        primarySwatch: Colors.blueGrey, // 기본 색상
        scaffoldBackgroundColor: const Color(0xFF1A1A1A), // 배경 색상 (어두운 회색)
        brightness: Brightness.dark, // 어두운 테마
      ),
      // 홈 화면 (노트 목록 화면)
      home: NotesHomePage(onToggleTheme: toggleTheme, currentTheme: themeMode),
    );
  }
}

/// 노트 홈페이지 위젯 - 노트 목록과 편집 화면을 담당
class NotesHomePage extends StatefulWidget {
  final VoidCallback onToggleTheme; // 테마 전환 콜백 함수
  final ThemeMode currentTheme; // 현재 테마 모드

  const NotesHomePage({
    super.key,
    required this.onToggleTheme,
    required this.currentTheme,
  });

  @override
  State<NotesHomePage> createState() => _NotesHomePageState();
}

/// 노트 홈페이지의 상태를 관리하는 클래스
/// 애니메이션을 위한 믹스인 포함
class _NotesHomePageState extends State<NotesHomePage>
    with SingleTickerProviderStateMixin {
  // ==================== UI 상태 변수들 ====================
  int selectedMenuIndex = 0; // 선택된 사이드바 메뉴 인덱스 (0: 모든 노트, 1: 즐겨찾기 등)
  String? selectedFolderName; // 선택된 폴더 이름 (null이면 폴더 선택 안됨)
  Note? selectedNote; // 현재 편집 중인 노트
  Note? hoveredNote; // 마우스가 올라가 있는 노트 (데스크톱용)
  bool isEditMode = false; // 노트 편집 모드 활성화 여부
  bool isSelectionMode = false; // 다중 선택 모드 활성화 여부
  bool isSidebarCollapsed = false; // 사이드바 접힘 여부
  final Set<Note> selectedNotes = {}; // 선택된 노트들의 집합

  // ==================== 뷰 설정 변수들 ====================
  ViewMode viewMode = ViewMode.grid; // 현재 뷰 모드 (격자/목록/타임라인)
  SortMode sortMode = SortMode.modifiedDate; // 현재 정렬 모드 (수정일/생성일/이름/즐겨찾기)
  String searchQuery = ''; // 검색어
  bool isAutoSaving = false; // 자동 저장 중인지 표시

  // ==================== 애니메이션 컨트롤러 ====================
  late AnimationController _animationController; // 애니메이션 제어용

  // ==================== 데이터 리스트 ====================
  final List<Note> notes = []; // 모든 노트를 담는 리스트
  final List<Folder> folders = []; // 모든 폴더를 담는 리스트

  /// 위젯이 처음 생성될 때 호출되는 초기화 함수
  @override
  void initState() {
    super.initState();
    // 애니메이션 컨트롤러 초기화 (300ms 동안 애니메이션 실행)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  /// 위젯이 제거될 때 호출되는 정리 함수
  @override
  void dispose() {
    _animationController.dispose(); // 애니메이션 컨트롤러 해제
    super.dispose();
  }

  /// 새 노트의 제목을 자동으로 생성하는 함수
  /// 예: '새 노트 1', '새 노트 2', ... (중복되지 않도록)
  String _getNewNoteTitle() {
    int counter = 1; // 카운터 시작
    String newTitle;
    // 기존 노트들의 제목을 Set으로 만들어서 중복 체크 준비
    final existingTitles = notes.map((note) => note.title).toSet();

    // 중복되지 않는 제목을 찾을 때까지 반복
    while (true) {
      newTitle = '새 노트 $counter';
      if (!existingTitles.contains(newTitle)) {
        return newTitle; // 중복되지 않으면 반환
      }
      counter++; // 중복이면 카운터 증가
    }
  }

  /// 새 노트를 생성하는 함수
  void _createNewNote() {
    final newNote = Note(
      title: _getNewNoteTitle(), // 자동으로 제목 생성
      content: '내용을 입력하세요.', // 기본 내용
      date: DateTime.now(), // 현재 시간
      folderName: selectedFolderName, // 현재 선택된 폴더에 추가
    );
    setState(() {
      notes.insert(0, newNote); // 리스트 맨 앞에 새 노트 추가
      selectedNote = newNote; // 새 노트를 선택
      isEditMode = true; // 편집 모드로 전환
    });
  }

  /// 노트의 즐겨찾기 상태를 토글하는 함수 (⭐ 버튼 클릭 시)
  void _toggleStar(Note note) {
    setState(() {
      note.isStarred = !note.isStarred; // 즐겨찾기 상태 반전 (true ↔ false)
      _autoSave(); // 자동 저장 실행
    });
  }

  /// 선택된 노트들을 휴지통으로 이동하는 함수
  void _deleteSelectedNotes() {
    setState(() {
      for (var note in selectedNotes) {
        note.isInTrash = true; // 각 노트를 휴지통으로 표시
      }
      selectedNotes.clear(); // 선택 목록 초기화
      isSelectionMode = false; // 선택 모드 종료
    });
  }

  /// 선택된 노트들을 완전히 삭제하는 함수 (휴지통에서 영구 삭제)
  void _permanentlyDeleteSelectedNotes() {
    setState(() {
      notes.removeWhere((note) => selectedNotes.contains(note)); // 노트 리스트에서 제거
      selectedNotes.clear(); // 선택 목록 초기화
      isSelectionMode = false; // 선택 모드 종료
    });
  }

  /// 휴지통에 있는 선택된 노트들을 복원하는 함수
  void _restoreSelectedNotes() {
    setState(() {
      for (var note in selectedNotes) {
        note.isInTrash = false; // 휴지통 표시 제거
      }
      selectedNotes.clear(); // 선택 목록 초기화
      isSelectionMode = false; // 선택 모드 종료
    });
  }

  /// 다중 선택 모드를 토글하는 함수 (선택 모드 ON/OFF)
  void _toggleSelectionMode() {
    setState(() {
      isSelectionMode = !isSelectionMode; // 선택 모드 반전
      if (!isSelectionMode) {
        selectedNotes.clear(); // 선택 모드 종료 시 선택 목록 초기화
      }
    });
  }

  /// 노트 카드를 탭했을 때 호출되는 함수
  void _onNoteCardTap(Note note) {
    setState(() {
      if (isSelectionMode) {
        // 선택 모드일 때: 노트 선택/해제
        if (selectedNotes.contains(note)) {
          selectedNotes.remove(note); // 이미 선택되어 있으면 선택 해제
        } else {
          selectedNotes.add(note); // 선택되어 있지 않으면 선택
        }
      } else {
        // 일반 모드일 때: 노트 편집 모드로 진입
        selectedNote = note;
        isEditMode = true;
      }
    });
  }

  /// 자동 저장 표시를 보여주는 함수 (1초 동안 "저장 중..." 표시)
  void _autoSave() {
    setState(() {
      isAutoSaving = true; // 저장 중 표시 활성화
    });
    // 1초 후에 저장 중 표시 제거
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        // 위젯이 아직 존재하는지 확인
        setState(() {
          isAutoSaving = false; // 저장 중 표시 비활성화
        });
      }
    });
  }

  /// 현재 선택된 메뉴/폴더/검색어에 따라 필터링된 노트 목록을 반환하는 Getter
  /// 예: 즐겨찾기 메뉴 선택 시 → 즐겨찾기된 노트만 반환
  /// 예: "메모" 검색 시 → 제목이나 내용에 "메모"가 포함된 노트만 반환
  List<Note> get _filteredNotes {
    List<Note> filteredList;

    if (selectedMenuIndex == 3) {
      filteredList = notes.where((note) => note.isInTrash).toList();
    } else if (selectedMenuIndex == 4) {
      // 잠긴 노트
      filteredList = notes
          .where((note) => note.isLocked && !note.isInTrash)
          .toList();
    } else if (selectedMenuIndex == 5) {
      // 숨겨진 노트
      filteredList = notes
          .where((note) => note.isHidden && !note.isInTrash)
          .toList();
    } else {
      // 기본적으로 잠기거나 숨겨진 노트는 제외
      filteredList = notes
          .where((note) => !note.isInTrash && !note.isLocked && !note.isHidden)
          .toList();

      if (selectedFolderName != null) {
        filteredList = filteredList
            .where((note) => note.folderName == selectedFolderName)
            .toList();
      }

      if (selectedMenuIndex != -1) {
        switch (selectedMenuIndex) {
          case 0: // 모든 노트 (이미 필터링됨)
            break;
          case 1: // 즐겨찾기
            filteredList = filteredList
                .where((note) => note.isStarred)
                .toList();
            break;
          case 2: // 최근 노트
            filteredList = filteredList
                .where(
                  (note) => note.date.isAfter(
                    DateTime.now().subtract(const Duration(days: 7)),
                  ),
                )
                .toList();
            break;
        }
      }
    }

    if (searchQuery.isNotEmpty) {
      filteredList = filteredList
          .where(
            (note) =>
                note.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                note.content.toLowerCase().contains(searchQuery.toLowerCase()),
          )
          .toList();
    }

    switch (sortMode) {
      case SortMode.modifiedDate:
        filteredList.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortMode.createdDate:
        filteredList.sort((a, b) => b.createdDate.compareTo(a.createdDate));
        break;
      case SortMode.name:
        filteredList.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortMode.starred:
        filteredList.sort((a, b) {
          if (a.isStarred && !b.isStarred) return -1;
          if (!a.isStarred && b.isStarred) return 1;
          return b.date.compareTo(a.date);
        });
        break;
    }

    return filteredList;
  }

  void _onSidebarMenuTapped(int index) {
    setState(() {
      selectedMenuIndex = index;
      selectedFolderName = null;
    });
  }

  void _showQuickPreview(Note note) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 400,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (note.imageUrl != null)
                Text(note.imageUrl!, style: const TextStyle(fontSize: 50)),
              const SizedBox(height: 16),
              Expanded(child: SingleChildScrollView(child: Text(note.content))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${note.date.year}-${note.date.month}-${note.date.day}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 메인 화면을 빌드하는 함수 (위젯의 UI를 그림)
  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      // 키보드 단축키 설정
      bindings: {
        // Ctrl+N 키: 새 노트 생성
        const SingleActivator(LogicalKeyboardKey.keyN, control: true):
            _createNewNote,
        // Ctrl+F 키: 검색 포커스 (현재 미구현)
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
          // 검색 포커스 기능
        },
        // Delete 키: 선택된 노트 삭제
        const SingleActivator(LogicalKeyboardKey.delete): () {
          if (selectedNotes.isNotEmpty) _deleteSelectedNotes();
        },
      },
      child: Focus(
        autofocus: true,
        child: PopScope(
          // 뒤로가기 버튼 동작 설정
          canPop: !isEditMode, // 편집 모드가 아닐 때만 앱 종료
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }
            // 편집 모드일 때 뒤로가기를 누르면 목록 화면으로
            if (isEditMode) {
              setState(() {
                isEditMode = false;
                selectedNote = null;
              });
            }
          },
          child: Scaffold(
            // 메인 화면: 편집 모드면 드로잉 에디터, 아니면 노트 목록
            body: isEditMode && selectedNote != null
                ? DrawingEditor(
                    note: selectedNote!,
                    onBack: () {
                      // 뒤로가기 버튼 클릭 시
                      setState(() {
                        isEditMode = false;
                        selectedNote = null;
                      });
                    },
                    onSave: _autoSave, // 저장 시 자동저장 표시
                  )
                : _buildGridScreen(), // 노트 목록 화면
            // 플로팅 액션 버튼 (새 노트 생성 버튼)
            // 편집 모드나 선택 모드가 아닐 때만 표시
            floatingActionButton: !isEditMode && !isSelectionMode
                ? FloatingActionButton(
                    onPressed: _createNewNote,
                    backgroundColor: const Color(0xFF678AFB),
                    child: const Icon(Icons.edit_note, size: 30),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildGridScreen() {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isSidebarCollapsed ? 70 : 280,
          child: _buildSidebar(),
        ),
        Expanded(
          child: Column(
            children: [
              if (isSelectionMode)
                selectedMenuIndex == 3
                    ? _buildTrashSelectionHeader()
                    : _buildSelectionHeader()
              else if (selectedMenuIndex == 3)
                _buildTrashHeader()
              else
                _buildHeader(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildContentView(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentView() {
    if (_filteredNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_add_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '새 노트를 만들어보세요',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '오른쪽 아래의 버튼을 눌러 시작하세요.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    switch (viewMode) {
      case ViewMode.grid:
        return _buildGridView();
      case ViewMode.list:
        return _buildListView();
      case ViewMode.timeline:
        return _buildTimelineView();
    }
  }

  Widget _buildGridView() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = (constraints.maxWidth / 200).floor().clamp(
            2,
            6,
          );
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.75,
            ),
            itemCount: _filteredNotes.length,
            itemBuilder: (context, index) {
              final note = _filteredNotes[index];
              return NoteCard(
                note: note,
                isHovered: hoveredNote == note,
                isSelected: selectedNotes.contains(note),
                isSelectionMode: isSelectionMode,
                onTap: () => _onNoteCardTap(note),
                onLongPress: isSelectionMode ? null : _toggleSelectionMode,
                onHover: (isHovering) =>
                    setState(() => hoveredNote = isHovering ? note : null),
                onToggleStar: () => _toggleStar(note),
                onQuickPreview: () => _showQuickPreview(note),
                onMoreOptions: () => _showNoteContextMenu(note),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredNotes.length,
      itemBuilder: (context, index) {
        final note = _filteredNotes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  note.imageUrl ?? '📝',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            title: Text(
              note.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${note.date.year}-${note.date.month}-${note.date.day}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    note.isStarred ? Icons.star : Icons.star_border,
                    color: note.isStarred ? Colors.amber : Colors.grey,
                    size: 24,
                  ),
                  onPressed: () => _toggleStar(note),
                ),
                if (note.tags.isNotEmpty)
                  const Icon(Icons.label, color: Colors.blue, size: 20),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showNoteContextMenu(note),
                ),
              ],
            ),
            onTap: () => _onNoteCardTap(note),
          ),
        );
      },
    );
  }

  Widget _buildTimelineView() {
    final groupedNotes = <String, List<Note>>{};
    for (var note in _filteredNotes) {
      final dateKey = '${note.date.year}-${note.date.month}-${note.date.day}';
      groupedNotes.putIfAbsent(dateKey, () => []).add(note);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: groupedNotes.length,
      itemBuilder: (context, index) {
        final dateKey = groupedNotes.keys.elementAt(index);
        final notesForDate = groupedNotes[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                dateKey,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...notesForDate.map(
              (note) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(note.title),
                  subtitle: Text(note.content, maxLines: 1),
                  onTap: () => _onNoteCardTap(note),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 노트 더보기 메뉴 표시 - 다양한 편의 기능 제공
  void _showNoteContextMenu(Note note) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 제목 바
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 즐겨찾기
            ListTile(
              leading: Icon(
                note.isStarred ? Icons.star : Icons.star_border,
                color: note.isStarred ? Colors.amber : null,
              ),
              title: Text(note.isStarred ? '즐겨찾기 해제' : '즐겨찾기 추가'),
              subtitle: const Text('빠른 접근을 위해 즐겨찾기'),
              onTap: () {
                Navigator.pop(context);
                _toggleStar(note);
              },
            ),
            const Divider(),
            // 잠금
            ListTile(
              leading: Icon(
                note.isLocked ? Icons.lock_open : Icons.lock,
                color: note.isLocked ? Colors.orange : null,
              ),
              title: Text(note.isLocked ? '잠금 해제' : '노트 잠금'),
              subtitle: const Text('중요한 노트 보호하기'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  note.isLocked = !note.isLocked;
                  if (note.isLocked) note.isHidden = false;
                });
                _autoSave();
              },
            ),
            // 숨기기
            ListTile(
              leading: Icon(
                note.isHidden ? Icons.visibility : Icons.visibility_off,
                color: note.isHidden ? Colors.blue : null,
              ),
              title: Text(note.isHidden ? '숨기기 취소' : '노트 숨기기'),
              subtitle: const Text('목록에서 숨기기'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  note.isHidden = !note.isHidden;
                  if (note.isHidden) note.isLocked = false;
                });
                _autoSave();
              },
            ),
            const Divider(),
            // 폴더로 이동
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.purple),
              title: const Text('폴더로 이동'),
              subtitle: Text(note.folderName ?? '폴더 없음'),
              onTap: () {
                Navigator.pop(context);
                _showMoveToFolderDialog({note});
              },
            ),
            // 복사본 생성
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.teal),
              title: const Text('복사본 생성'),
              subtitle: const Text('이 노트의 사본 만들기'),
              onTap: () {
                Navigator.pop(context);
                _duplicateNote(note);
              },
            ),
            const Divider(),
            // 공유
            ListTile(
              leading: const Icon(Icons.share, color: Colors.green),
              title: const Text('공유'),
              subtitle: const Text('다른 사람과 공유하기'),
              onTap: () {
                Navigator.pop(context);
                _shareNote(note);
              },
            ),
            // 내보내기
            ListTile(
              leading: const Icon(Icons.upload, color: Colors.indigo),
              title: const Text('내보내기'),
              subtitle: const Text('PDF, 텍스트 등으로 내보내기'),
              onTap: () {
                Navigator.pop(context);
                _exportSingleNote(note);
              },
            ),
            const Divider(),
            // 휴지통으로 이동
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('휴지통으로 이동'),
              subtitle: const Text('30일 후 자동 삭제'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  note.isInTrash = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${note.title}을(를) 휴지통으로 이동했습니다'),
                    action: SnackBarAction(
                      label: '취소',
                      onPressed: () {
                        setState(() {
                          note.isInTrash = false;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 노트 복사본 생성 함수
  void _duplicateNote(Note originalNote) {
    final duplicatedNote = Note(
      title: '${originalNote.title} (사본)',
      content: originalNote.content,
      date: DateTime.now(),
      folderName: originalNote.folderName,
      tags: List.from(originalNote.tags),
      strokes: List.from(originalNote.strokes),
      imageUrl: originalNote.imageUrl,
    );
    setState(() {
      notes.insert(notes.indexOf(originalNote) + 1, duplicatedNote);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${originalNote.title}의 복사본을 생성했습니다')),
    );
  }

  /// 단일 노트 내보내기 함수
  void _exportSingleNote(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('내보내기 형식 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('PDF'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${note.title}을(를) PDF로 내보내는 중...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet, color: Colors.blue),
              title: const Text('텍스트 파일'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${note.title}을(를) 텍스트로 내보내는 중...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.green),
              title: const Text('이미지'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${note.title}을(를) 이미지로 내보내는 중...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMoveToFolderDialog(Set<Note> notesToMove) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${notesToMove.length}개의 노트를 폴더로 이동'),
        content: SizedBox(
          width: 300,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('없음 (폴더에서 제거)'),
                onTap: () {
                  setState(() {
                    for (var note in notesToMove) {
                      note.folderName = null;
                    }
                    isSelectionMode = false;
                    selectedNotes.clear();
                  });
                  Navigator.pop(context);
                },
              ),
              ...folders.map(
                (folder) => ListTile(
                  title: Text(folder.name),
                  onTap: () {
                    setState(() {
                      for (var note in notesToMove) {
                        note.folderName = folder.name;
                      }
                      isSelectionMode = false;
                      selectedNotes.clear();
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareNote(Note note) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${note.title} 공유하기')));
  }

  Widget _buildSidebar() {
    if (isSidebarCollapsed) {
      return Container(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF3E3E3E)
            : const Color(0xFF3E3E3E),
        child: Column(
          children: [
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                setState(() {
                  isSidebarCollapsed = false;
                });
              },
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF3E3E3E)
            : const Color(0xFF3E3E3E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildSidebarHeader(),
            _buildSidebarSearchBar(),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSidebarItem(
                      Icons.all_inbox,
                      '모든 노트',
                      notes.where((n) => !n.isInTrash).length,
                      0,
                    ),
                    _buildSidebarItem(
                      Icons.star_border,
                      '즐겨찾기',
                      notes.where((n) => n.isStarred && !n.isInTrash).length,
                      1,
                    ),
                    _buildSidebarItem(
                      Icons.access_time,
                      '최근 노트',
                      notes.where((n) => !n.isInTrash).take(5).length,
                      2,
                    ),
                    const Divider(
                      color: Colors.white24,
                      height: 24,
                      indent: 16,
                      endIndent: 16,
                    ),
                    _buildSidebarItem(
                      Icons.lock_outline,
                      '잠긴 노트',
                      notes.where((n) => n.isLocked && !n.isInTrash).length,
                      4,
                    ),
                    _buildSidebarItem(
                      Icons.visibility_off_outlined,
                      '숨겨진 노트',
                      notes.where((n) => n.isHidden && !n.isInTrash).length,
                      5,
                    ),
                    const Divider(
                      color: Colors.white24,
                      height: 24,
                      indent: 16,
                      endIndent: 16,
                    ),
                    _buildFolderSection(),
                    const Divider(
                      color: Colors.white24,
                      height: 24,
                      indent: 16,
                      endIndent: 16,
                    ),
                    _buildSidebarItem(
                      Icons.delete_outline,
                      '휴지통',
                      notes.where((n) => n.isInTrash).length,
                      3,
                    ),
                  ],
                ),
              ),
            ),
            _buildSidebarFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF678AFB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.note_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Samsung Notes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              widget.currentTheme == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: Colors.white,
              size: 20,
            ),
            onPressed: widget.onToggleTheme,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
            onSelected: (value) {
              switch (value) {
                case 'new_note':
                  _createNewNote();
                  break;
                case 'new_folder':
                  _showCreateFolderDialog();
                  break;
                case 'collapse':
                  setState(() {
                    isSidebarCollapsed = true;
                  });
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'new_note', child: Text('새 노트')),
              const PopupMenuItem(value: 'new_folder', child: Text('새 폴더')),
              const PopupMenuItem(value: 'collapse', child: Text('사이드바 접기')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: TextField(
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: '노트 검색...',
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
            prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 18),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2A),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showSettingsDialog,
                  icon: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    '설정',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          if (isAutoSaving) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.grey[400]!,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '저장 중...',
                  style: TextStyle(color: Colors.grey[400], fontSize: 10),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<Map<String, double>> _getStorageInfo() async {
    // 저장 공간 정보를 임시로 반환 (disk_space 패키지 제거됨)
    return {'total': 128.0 * 1024, 'free': 64.0 * 1024}; // 128GB 총, 64GB 여유
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : Colors.white,
        title: const Text('설정'),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        content: SizedBox(
          width: 400,
          child: ListView(
            shrinkWrap: true,
            children: [
              // 저장 공간
              FutureBuilder<Map<String, double>>(
                future: _getStorageInfo(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data == null) {
                    return const ListTile(title: Text('저장 공간 정보를 불러올 수 없습니다.'));
                  }

                  final totalSpaceMB = snapshot.data!['total']!;
                  final freeSpaceMB = snapshot.data!['free']!;
                  final usedSpaceMB = totalSpaceMB - freeSpaceMB;
                  final usedPercentage = totalSpaceMB > 0
                      ? usedSpaceMB / totalSpaceMB
                      : 0.0;

                  final totalSpaceGB = (totalSpaceMB / 1024).toStringAsFixed(1);
                  final usedSpaceGB = (usedSpaceMB / 1024).toStringAsFixed(1);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.storage,
                              size: 20,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '저장 공간',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$usedSpaceGB GB / $totalSpaceGB GB 사용 중',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: usedPercentage,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF678AFB),
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // 설정 항목들
              ListTile(
                leading: const Icon(Icons.fingerprint),
                title: const Text('잠금 설정'),
                subtitle: const Text('생체 인증으로 노트 보호'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('언어'),
                subtitle: const Text('한국어'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: const Text('기본 글꼴'),
                subtitle: const Text('시스템 기본'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('알림'),
                subtitle: const Text('알림 설정 관리'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('정보'),
                subtitle: const Text('버전 1.0.0'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('도움말'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('개인정보 처리방침'),
                onTap: () {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, int count, int index) {
    final isSelected = selectedMenuIndex == index;
    return InkWell(
      onTap: () => _onSidebarMenuTapped(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5A5A5A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF678AFB) : Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.folder, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              const Text(
                '폴더',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: _showCreateFolderDialog,
                child: const Icon(Icons.add, color: Colors.white70, size: 18),
              ),
            ],
          ),
        ),
        ...folders.map((folder) => _buildFolderTile(folder)),
      ],
    );
  }

  Widget _buildFolderTile(Folder folder) {
    final isSelected = selectedFolderName == folder.name;
    final folderNoteCount = notes
        .where((n) => n.folderName == folder.name && !n.isInTrash)
        .length;

    return InkWell(
      onTap: () {
        setState(() {
          selectedFolderName = folder.name;
          selectedMenuIndex = -1;
        });
      },
      onLongPress: () => _showFolderOptionsMenu(folder),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5A5A5A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.folder_outlined, color: folder.color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                folder.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (folderNoteCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? folder.color : Colors.white12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  folderNoteCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFolderOptionsMenu(Folder folder) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('이름 변경'),
              onTap: () {
                Navigator.pop(context);
                _renameFolderDialog(folder);
              },
            ),
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: const Text('색상 변경'),
              onTap: () {
                Navigator.pop(context);
                _changeFolderColor(folder);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('삭제', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteFolderDialog(folder);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _changeFolderColor(Folder folder) {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.pink,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('폴더 색상 선택'),
        content: Wrap(
          spacing: 10,
          children: colors.map((color) {
            return InkWell(
              onTap: () {
                setState(() {
                  folder.color = color;
                });
                Navigator.pop(context);
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: folder.color == color
                        ? Colors.black
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _renameFolderDialog(Folder folder) {
    final controller = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('폴더 이름 변경'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  folder.name = controller.text;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 폴더 만들기'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '폴더 이름'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  folders.add(Folder(name: controller.text, count: 0));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('만들기'),
          ),
        ],
      ),
    );
  }

  void _deleteFolderDialog(Folder folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('폴더 삭제'),
        content: Text('${folder.name} 폴더를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                folders.remove(folder);
                if (selectedFolderName == folder.name) {
                  selectedFolderName = null;
                  selectedMenuIndex = 0;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    String title = '모든 노트';
    if (selectedFolderName != null) {
      title = selectedFolderName!;
    } else {
      switch (selectedMenuIndex) {
        case 1:
          title = '즐겨찾기';
          break;
        case 2:
          title = '최근 노트';
          break;
        case 4:
          title = '잠긴 노트';
          break;
        case 5:
          title = '숨겨진 노트';
          break;
      }
    }

    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2A2A2A)
          : const Color(0xFF5A5A5A),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _filteredNotes.length.toString(),
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          const SizedBox(width: 20),
          PopupMenuButton<SortMode>(
            icon: Row(
              children: [
                const Icon(Icons.sort, color: Colors.white, size: 20),
                const SizedBox(width: 4),
                Text(
                  _getSortModeText(sortMode),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
            onSelected: (mode) {
              setState(() {
                sortMode = mode;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortMode.modifiedDate,
                child: Text('최근 수정일'),
              ),
              const PopupMenuItem(
                value: SortMode.createdDate,
                child: Text('생성일'),
              ),
              const PopupMenuItem(value: SortMode.name, child: Text('이름')),
              const PopupMenuItem(
                value: SortMode.starred,
                child: Text('즐겨찾기 우선'),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  viewMode == ViewMode.grid
                      ? Icons.grid_view
                      : viewMode == ViewMode.list
                      ? Icons.view_list
                      : Icons.timeline,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    viewMode = ViewMode
                        .values[(viewMode.index + 1) % ViewMode.values.length];
                  });
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.select_all),
                            title: const Text('모두 선택'),
                            onTap: () {
                              Navigator.pop(context);
                              _toggleSelectionMode();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.download),
                            title: const Text('내보내기'),
                            onTap: () {
                              Navigator.pop(context);
                              _exportNotes();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSortModeText(SortMode mode) {
    switch (mode) {
      case SortMode.modifiedDate:
        return '최근 수정일';
      case SortMode.createdDate:
        return '생성일';
      case SortMode.name:
        return '이름순';
      case SortMode.starred:
        return '즐겨찾기';
    }
  }

  void _exportNotes() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('노트를 내보내는 중...')));
  }

  Widget _buildSelectionHeader() {
    return Container(
      color: const Color(0xFF5A5A5A),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _toggleSelectionMode,
          ),
          Text(
            '${selectedNotes.length}개 선택됨',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.folder, color: Colors.white),
            onPressed: () {
              if (selectedNotes.isNotEmpty) {
                _showMoveToFolderDialog(selectedNotes);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: selectedNotes.isNotEmpty ? _deleteSelectedNotes : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTrashHeader() {
    return Container(
      color: const Color(0xFF5A5A5A),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          const Text(
            '휴지통',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _filteredNotes.length.toString(),
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                notes.removeWhere((note) => note.isInTrash);
              });
            },
            child: const Text('모두 비우기', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTrashSelectionHeader() {
    return Container(
      color: const Color(0xFF5A5A5A),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _toggleSelectionMode,
          ),
          Text(
            '${selectedNotes.length}개 선택됨',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const Spacer(),
          TextButton(
            onPressed: _restoreSelectedNotes,
            child: const Text('복원', style: TextStyle(color: Colors.white)),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_forever_outlined,
              color: Colors.white,
            ),
            onPressed: _permanentlyDeleteSelectedNotes,
          ),
        ],
      ),
    );
  }
}

// ====================================================
// 3. 그리기 에디터 위젯
// ====================================================

/// 노트를 편집하고 그림을 그릴 수 있는 에디터 위젯
class DrawingEditor extends StatefulWidget {
  final Note note; // 편집할 노트
  final VoidCallback onBack; // 뒤로가기 버튼 콜백
  final VoidCallback onSave; // 저장 콜백

  const DrawingEditor({
    super.key,
    required this.note,
    required this.onBack,
    required this.onSave,
  });

  @override
  State<DrawingEditor> createState() => _DrawingEditorState();
}

/// 그리기 에디터의 상태를 관리하는 클래스
class _DrawingEditorState extends State<DrawingEditor> {
  // ==================== 그리기 상태 변수들 ====================
  List<DrawingStroke> strokes = []; // 그려진 모든 선들
  List<Offset> currentStroke = []; // 현재 그리고 있는 선의 점들
  List<DrawingStroke> undoneStrokes = []; // 실행 취소된 선들 (다시 실행용)
  DrawingTool selectedTool = DrawingTool.pen; // 현재 선택된 도구 (기본: 펜)
  Color selectedColor = Colors.black; // 현재 선택된 색상 (기본: 검정)
  double strokeWidth = 3.0; // 선의 굵기 (기본: 3.0)

  /// 색상 팔레트 - 사용자가 선택할 수 있는 색상 목록
  final List<Color> colorPalette = [
    Colors.black, // 검정
    Colors.red, // 빨강
    Colors.blue, // 파랑
    Colors.green, // 초록
    Colors.yellow, // 노랑
    Colors.orange, // 주황
    Colors.purple, // 보라
  ];

  /// 위젯 초기화 - 노트에 저장된 기존 그림 불러오기
  @override
  void initState() {
    super.initState();
    strokes = List.from(widget.note.strokes); // 노트의 스트로크를 복사
  }

  /// 그리기 시작 - 손가락이나 마우스를 눌렀을 때
  void _onPanStart(DragStartDetails details) {
    setState(() {
      currentStroke = [details.localPosition]; // 첫 점 추가
      undoneStrokes.clear(); // 새로 그리기 시작하면 다시 실행 목록 초기화
    });
  }

  /// 그리기 중 - 손가락이나 마우스를 드래그할 때
  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      currentStroke.add(details.localPosition); // 현재 선에 점 추가
    });
  }

  /// 그리기 종료 - 손가락이나 마우스를 뗐을 때
  void _onPanEnd(DragEndDetails details) {
    if (currentStroke.isNotEmpty) {
      setState(() {
        // 완성된 선을 스트로크 리스트에 추가
        strokes.add(
          DrawingStroke(
            points: List.from(currentStroke), // 현재 선의 점들 복사
            color: selectedColor, // 선택된 색상
            width: strokeWidth, // 선택된 굵기
            tool: selectedTool, // 선택된 도구
          ),
        );
        currentStroke = []; // 현재 선 초기화
        widget.note.strokes = List.from(strokes); // 노트에 저장
        widget.onSave(); // 자동 저장 실행
      });
    }
  }

  /// 실행 취소 - 마지막으로 그린 선 제거
  void _undo() {
    if (strokes.isNotEmpty) {
      setState(() {
        undoneStrokes.add(strokes.removeLast()); // 마지막 선을 다시 실행 목록으로 이동
        widget.note.strokes = List.from(strokes); // 노트에 저장
        widget.onSave(); // 자동 저장 실행
      });
    }
  }

  /// 다시 실행 - 실행 취소한 선 복원
  void _redo() {
    if (undoneStrokes.isNotEmpty) {
      setState(() {
        strokes.add(undoneStrokes.removeLast()); // 다시 실행 목록에서 선을 가져와 복원
        widget.note.strokes = List.from(strokes); // 노트에 저장
        widget.onSave(); // 자동 저장 실행
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildEditorAppBar(),
        _buildDrawingToolbar(),
        Expanded(child: _buildCanvas()),
      ],
    );
  }

  Widget _buildCanvas() {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Container(
        color: Colors.white,
        child: CustomPaint(
          painter: DrawingPainter(
            strokes: strokes,
            currentStroke: currentStroke,
            currentColor: selectedColor,
            currentWidth: strokeWidth,
            currentTool: selectedTool,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }

  Widget _buildEditorAppBar() {
    return Container(
      height: 60,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: widget.onBack,
          ),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: widget.note.title),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: '제목',
              ),
              onChanged: (value) {
                widget.note.title = value;
                widget.onSave();
              },
            ),
          ),
          IconButton(
            icon: Icon(
              widget.note.isStarred ? Icons.star : Icons.star_border,
              color: widget.note.isStarred ? Colors.amber : Colors.black,
            ),
            onPressed: () {
              setState(() {
                widget.note.isStarred = !widget.note.isStarred;
              });
              widget.onSave();
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingToolbar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildToolButton(Icons.brush, DrawingTool.pen),
          _buildToolButton(Icons.edit, DrawingTool.pencil),
          _buildToolButton(Icons.format_color_text, DrawingTool.highlighter),
          _buildToolButton(Icons.cleaning_services, DrawingTool.eraser),
          const VerticalDivider(),
          ...colorPalette.map((color) => _buildColorButton(color)),
          const Spacer(),
          SizedBox(
            width: 150,
            child: Slider(
              value: strokeWidth,
              min: 1,
              max: 10,
              onChanged: (value) {
                setState(() {
                  strokeWidth = value;
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: strokes.isNotEmpty ? _undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: undoneStrokes.isNotEmpty ? _redo : null,
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, DrawingTool tool) {
    final isSelected = selectedTool == tool;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: isSelected
          ? BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: IconButton(
        icon: Icon(icon, color: Colors.black),
        onPressed: () {
          setState(() {
            selectedTool = tool;
          });
        },
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    final isSelected = selectedColor == color;
    return InkWell(
      onTap: () {
        setState(() {
          selectedColor = color;
        });
      },
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : null,
      ),
    );
  }
}

// ====================================================
// 4. 노트 카드 위젯
// ====================================================

/// 노트 목록에서 하나의 노트를 표시하는 카드 위젯
/// 격자 뷰에서 사용됨
class NoteCard extends StatelessWidget {
  final Note note; // 표시할 노트
  final bool isHovered; // 마우스 오버 상태 (데스크톱용)
  final bool isSelected; // 선택 상태
  final bool isSelectionMode; // 선택 모드 활성화 여부
  final VoidCallback onTap; // 탭 이벤트 콜백
  final VoidCallback? onLongPress; // 롱프레스 이벤트 콜백
  final ValueChanged<bool> onHover; // 호버 이벤트 콜백
  final VoidCallback onToggleStar; // 즐겨찾기 토글 콜백
  final VoidCallback onQuickPreview; // 빠른 미리보기 콜백
  final VoidCallback onMoreOptions; // 더보기 메뉴 콜백

  const NoteCard({
    super.key,
    required this.note,
    required this.isHovered,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    this.onLongPress,
    required this.onHover,
    required this.onToggleStar,
    required this.onQuickPreview,
    required this.onMoreOptions,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: isHovered ? 8 : 4,
                offset: Offset(0, isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              _buildCardContent(context),
              _buildStarButton(context),
              if (isSelectionMode) _buildSelectionIndicator(context),
              if (isHovered && !isSelectionMode) _buildQuickPreviewButton(),
              if (!isSelectionMode) _buildMoreOptionsButton(context),
              if (note.isLocked) _buildLockedOverlay(),
              if (note.isHidden) _buildHiddenOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: CustomPaint(
              painter: DrawingPainter(
                strokes: note.strokes,
                currentStroke: const [],
                currentColor: Colors.transparent,
                currentWidth: 0,
                currentTool: DrawingTool.pen,
              ),
              child: Center(child: Text(note.content)),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.title.isNotEmpty)
                  Text(
                    note.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                if (note.content.isNotEmpty)
                  Text(
                    note.content,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStarButton(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: GestureDetector(
        onTap: onToggleStar,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            note.isStarred ? Icons.star : Icons.star_border,
            color: note.isStarred ? Colors.amber : Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionIndicator(BuildContext context) {
    return Positioned(
      top: 4,
      left: 4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isSelected ? Colors.blue : Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildQuickPreviewButton() {
    return Positioned(
      bottom: 8,
      right: 8,
      child: IconButton(
        icon: const Icon(Icons.visibility, size: 20),
        onPressed: onQuickPreview,
      ),
    );
  }

  /// 더보기 버튼 위젯 - 왼쪽 상단의 삼지창 아이콘
  Widget _buildMoreOptionsButton(BuildContext context) {
    return Positioned(
      top: 8,
      left: 8,
      child: GestureDetector(
        onTap: onMoreOptions,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.more_vert, size: 20, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildLockedOverlay() {
    return const Positioned.fill(
      child: Center(child: Icon(Icons.lock, size: 40, color: Colors.white54)),
    );
  }

  Widget _buildHiddenOverlay() {
    return const Positioned.fill(
      child: Center(
        child: Icon(Icons.visibility_off, size: 40, color: Colors.white54),
      ),
    );
  }
}

// ====================================================
// 5. 커스텀 페인터 (그리기용)
// ====================================================

/// 캔버스에 그림을 그리는 커스텀 페인터 클래스
/// 플러터의 기본 페인터를 상속받아 직접 그리기 로직을 구현
class DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes; // 그려진 모든 선들
  final List<Offset> currentStroke; // 현재 그리고 있는 선
  final Color currentColor; // 현재 선택된 색상
  final double currentWidth; // 현재 선의 굵기
  final DrawingTool currentTool; // 현재 선택된 도구

  DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.currentColor,
    required this.currentWidth,
    required this.currentTool,
  });

  /// 실제로 캔버스에 그림을 그리는 함수
  @override
  void paint(Canvas canvas, Size size) {
    // 1. 저장된 모든 선 그리기
    for (var stroke in strokes) {
      final isHighlighter = stroke.tool == DrawingTool.highlighter; // 형광펜 여부 체크
      final paint = Paint()
        ..color = isHighlighter
            ? stroke.color.withValues(alpha: 0.3) // 형광펜은 반투명
            : stroke
                  .color // 일반 도구는 불투명
        ..strokeWidth = isHighlighter
            ? stroke.width * 2
            : stroke
                  .width // 형광펜은 2배 굵게
        ..strokeCap = StrokeCap
            .round // 선 끝을 둥글게
        ..style = PaintingStyle.stroke; // 선 그리기 스타일

      // 점들을 연결해서 선 그리기 (점 i와 점 i+1을 연결)
      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }

    // 2. 현재 그리고 있는 선 그리기 (실시간 미리보기)
    if (currentStroke.isNotEmpty) {
      final isHighlighter = currentTool == DrawingTool.highlighter;
      final paint = Paint()
        ..color = isHighlighter
            ? currentColor.withValues(alpha: 0.3)
            : currentColor
        ..strokeWidth = isHighlighter ? currentWidth * 2 : currentWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // 현재 선의 점들을 연결해서 그리기
      for (int i = 0; i < currentStroke.length - 1; i++) {
        canvas.drawLine(currentStroke[i], currentStroke[i + 1], paint);
      }
    }
  }

  /// 다시 그려야 하는지 여부를 판단하는 함수
  /// true를 반환하면 항상 다시 그림 (그리기 중에는 계속 업데이트 필요)
  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
