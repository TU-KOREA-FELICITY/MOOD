import 'package:flutter/material.dart';
import 'package:mood/ui/CategoryTagScreen.dart';
import 'package:mood/services/spotify_service.dart';


class SearchView extends StatefulWidget {
  final SpotifyService spotifyService;
  final Function(int) onTabChange;

  const SearchView({Key? key, required this.spotifyService, required this.onTabChange}) : super(key: key);

  @override
  _SearchViewState createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showCancelIcon = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _searchResults = [];
  List<String> recentSearches = [];
  late TabController _tabController;
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // TabController 초기화
    _focusNode.addListener(() {
      setState(() {
        _showCancelIcon = _searchController.text.isNotEmpty; // 검색어가 있을 때 취소 버튼 표시
      });
    });
    _searchController.addListener(() {
      setState(() {
        _showCancelIcon = _searchController.text.isNotEmpty; // 검색어가 있을 때 취소 버튼 표시
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose(); // TabController 해제
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addToRecentSearches(String query) {
    setState(() {
      recentSearches.remove(query);
      recentSearches.insert(0, query);
      if (recentSearches.length > 5) {
        recentSearches.removeLast();
      }
    });
  }

  void _performSearch() async {
    final query = _searchController.text;
    if (query.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });
      _addToRecentSearches(query);
      List<dynamic> searchResultsDynamic = await widget.spotifyService.searchTracks(query);
      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(searchResultsDynamic);
        _isLoading = false;
      });
      if (_searchResults.isNotEmpty) {

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 결과가 없습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: '곡, 아티스트 검색',
                          hintStyle: TextStyle(color: Colors.grey),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.search, color: Colors.black),
                            onPressed: _performSearch,
                          ),
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                        onSubmitted: (_) => _performSearch(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        // 취소 버튼 클릭 시 검색어 초기화
                        _searchResults.clear();
                        _searchController.clear();
                      });
                      _focusNode.unfocus();
                    },
                    child: Text(
                      '취소',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            CategoryTagScreen(),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        iconSize: 30,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '검색'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '프로필'),
        ],
        currentIndex: _currentIndex,
        onTap:(index) {
            setState(() {
              _currentIndex = index;
            });
          widget.onTabChange(index);
        },
        backgroundColor :Colors.white,
        selectedItemColor : Color(0xFF014FFA),
        unselectedItemColor : Colors.grey,
        type : BottomNavigationBarType.fixed,
        elevation :8 ,
      ),
    );
  }

  Widget _buildCategoryCard(String title, Color color) {
    return Container(
        decoration:
        BoxDecoration(color : color , borderRadius : BorderRadius.circular(12)),
        child:
        Padding(padding :
        const EdgeInsets.all(8.0),
            child:
            Column(crossAxisAlignment :
            CrossAxisAlignment.start , mainAxisAlignment :
            MainAxisAlignment.spaceBetween , children:[
              Text('Playlist',
                  style:
                  TextStyle(color :
                  Colors.grey[700], fontSize :
                  10)),
              Text(title,
                  style:
                  const TextStyle(color :
                  Colors.black87, fontSize :
                  14 , fontWeight :
                  FontWeight.bold)),
            ])));
  }
}
