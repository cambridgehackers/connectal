/* Copyright (c) 2013 Quanta Research Cambridge, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

static int sockfd;
#define SOCK_NAME "socket_for_nandsim"
void wait_for_connect_nandsim_exe()
{
  int listening_socket;

  if ((listening_socket = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    fprintf(stderr, "%s: socket error %s",__FUNCTION__, strerror(errno));
    exit(1);
  }

  struct sockaddr_un local;
  local.sun_family = AF_UNIX;
  strcpy(local.sun_path, SOCK_NAME);
  unlink(local.sun_path);
  int len = strlen(local.sun_path) + sizeof(local.sun_family);
  if (bind(listening_socket, (struct sockaddr *)&local, len) == -1) {
    fprintf(stderr, "%s[%d]: bind error %s\n",__FUNCTION__, listening_socket, strerror(errno));
    exit(1);
  }

  if (listen(listening_socket, 5) == -1) {
    fprintf(stderr, "%s[%d]: listen error %s\n",__FUNCTION__, listening_socket, strerror(errno));
    exit(1);
  }
  
  //fprintf(stderr, "%s[%d]: waiting for a connection...\n",__FUNCTION__, listening_socket);
  if ((sockfd = accept(listening_socket, NULL, NULL)) == -1) {
    fprintf(stderr, "%s[%d]: accept error %s\n",__FUNCTION__, listening_socket, strerror(errno));
    exit(1);
  }
  remove(SOCK_NAME);  // we are connected now, so we can remove named socket
}

unsigned int read_from_nandsim_exe()
{
  unsigned int rv;
  if(recv(sockfd, &rv, sizeof(rv), 0) == -1){
    fprintf(stderr, "%s recv error\n",__FUNCTION__);
    exit(1);	  
  }
  return rv;
}
