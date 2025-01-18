// views (search_view 와 유사함,)

import 'package:flutter/material.dart';
import 'CategoryTagScreen.dart';

class SearchView2 extends StatefulWidget {
  const SearchView2({Key? key}) : super(key: key);

  @override
  _SearchView2State createState() => _SearchView2State();
}

class _SearchView2State extends State<SearchView2> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  bool _showCancelIcon = false;

  List<String> recentSearches = [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isSearching = _focusNode.hasFocus;
      });
    });
    _searchController.addListener(() {
      setState(() {
        _showCancelIcon = _searchController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 검색 헤더
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
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: '곡, 아티스트 검색',
                          hintStyle: TextStyle(color: Colors.black),
                          prefixIcon: Icon(Icons.search, color: Colors.black),
                          suffixIcon: _showCancelIcon
                              ? IconButton(
                            icon: Icon(Icons.cancel, color: Colors.grey[600]),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _showCancelIcon = false;
                              });
                            },
                          )
                              : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            _addToRecentSearches(value);
                            _searchController.clear();
                          }
                        },
                      ),
                    ),
                  ),
                  if (_isSearching)
                    Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isSearching = false;
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
                    ),
                ],
              ),
            ),
            // 최근 검색어 섹션
            Expanded(
              child: _isSearching
                  ? Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '최근 검색',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    // 최근 검색어 리스트
                    Expanded(
                      child: ListView.builder(
                        itemCount: recentSearches.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              child: Icon(Icons.history, color: Colors.grey[800]),
                            ),
                            title: Text(
                              recentSearches[index],
                              style: TextStyle(color: Colors.grey[800]),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.close, color: Colors.grey[800]),
                              onPressed: () {
                                setState(() {
                                  recentSearches.removeAt(index);
                                });
                              },
                            ),
                            onTap: () {
                              _searchController.text = recentSearches[index];
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
                  : CategoryTagScreen(),
            ),
          ],
        ),
      ),
    );
  }
}

