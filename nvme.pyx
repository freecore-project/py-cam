# cython: language_level=3, c_string_type=unicode, c_string_encoding=default
#-
# Copyright (c) 2020 iXsystems, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#

cimport defs
from libc cimport errno
import os
from posix.ioctl cimport ioctl
from posix.strings cimport bzero
from libc.string cimport memset
from libc.stdint cimport uint8_t, uint16_t, uint32_t, uint64_t


cdef extern from "sys/fcntl.h" nogil:
    int open(const char *, int)
    int close(int)

    enum:
        O_RDONLY


cdef extern from "dev/nvme/nvme.h" nogil:
    int NVME_GET_NSID
    int NVME_PASSTHROUGH_CMD

    void nvme_resv_status_swapbytes(void *, size_t)
    int NVME_STATUS_GET_SC(uint16_t)
    int NVME_STATUS_GET_SCT(uint16_t)

    struct nvme_get_nsid:
        char cdev[256]
        uint32_t nsid

    struct nvme_command:
        uint8_t opc
        uint8_t fuse
        uint16_t cid
        uint32_t nsid
        uint32_t rsvd2
        uint32_t rsvd3
        uint64_t mptr
        uint64_t prp1
        uint64_t prp2
        uint32_t cdw10
        uint32_t cdw11
        uint32_t cdw12
        uint32_t cdw13
        uint32_t cdw14
        uint32_t cdw15

    struct nvme_completion:
        uint32_t cdw0
        uint32_t rsvd1
        uint16_t sqhd
        uint16_t sqid
        uint16_t cid
        uint16_t status

    struct nvme_pt_command:
        nvme_command cmd
        nvme_completion cpl
        void * buf
        uint32_t len
        uint32_t is_read
        void * driver_lock

    struct nvme_resv_reg_ctrlr:
        uint16_t ctrlr_id
        uint8_t rcsts
        uint64_t hostid
        uint64_t rkey

    struct nvme_resv_status:
        uint32_t gen
        uint8_t rtype
        uint8_t regctl[2]
        uint8_t ptpls
        nvme_resv_reg_ctrlr ctrlr[0]

    enum nvme_nvm_opcode:
        NVME_OPC_RESERVATION_REPORT
        NVME_OPC_RESERVATION_ACQUIRE
        NVME_OPC_RESERVATION_REGISTER
        NVME_OPC_RESERVATION_RELEASE


def get_nsid(path):
    cdef nvme_get_nsid nsid
    cdef int fd = os.open(path, os.O_RDONLY)
    if fd == -1:
        raise OSError(errno.errno, os.strerror(errno.errno), path)
    try:
        with nogil:
            res = ioctl(fd, NVME_GET_NSID, &nsid)
        if res == -1:
            raise OSError(errno.errno, os.strerror(errno.errno), path)

        return nsid.cdev, nsid.nsid
    finally:
        os.close(fd)


cdef class NvmeDevice(object):

    cdef const char *dev
    cdef int fd

    def __cinit__(self, path):

        self.dev = path
        with nogil:
            self.fd = open(self.dev, O_RDONLY)
            if self.fd == -1:
                raise OSError(f'Failed to open: {self.dev}')

    def __dealloc__(self):

        with nogil:
            if self.fd != -1:
                close(self.fd)

    def resvacquire(self, crkey=0, prkey=0, racqa=0, rtype=0):
        cdef nvme_pt_command pt
        cdef uint64_t data[2]
        cdef uint32_t nsid
        cdef uint64_t icrkey = crkey
        cdef uint64_t iprkey = prkey
        cdef uint8_t iracqa = racqa
        cdef uint8_t irtype = rtype

        data[0] = defs.htole64(icrkey)
        data[1] = defs.htole64(iprkey)

        memset(&pt, 0, sizeof(pt))
        pt.cmd.opc = NVME_OPC_RESERVATION_ACQUIRE
        pt.cmd.cdw10 = defs.htole32((iracqa & 7) | (irtype << 8))
        pt.buf = &data
        pt.len = sizeof(data)
        pt.is_read = 0

        with nogil:
            res = ioctl(self.fd, NVME_PASSTHROUGH_CMD, &pt)
            if res == -1:
                raise OSError('Acquire request failed')

            sc = NVME_STATUS_GET_SC(pt.cpl.status)
            st = NVME_STATUS_GET_SCT(pt.cpl.status)
            if sc != 0 or st != 0:
                raise OSError('Acquire request returned error')

        return True

    def resvregister(self, crkey=0, nrkey=0, rrega=0, iekey=False, cptpl=2):
        cdef nvme_pt_command pt
        cdef uint64_t data[2]
        cdef uint32_t nsid
        cdef uint64_t icrkey = crkey
        cdef uint64_t inrkey = nrkey
        cdef uint8_t irrega = rrega
        cdef bint iiekey = iekey
        cdef uint8_t icptpl = cptpl

        data[0] = defs.htole64(icrkey)
        data[1] = defs.htole64(inrkey)

        memset(&pt, 0, sizeof(pt))
        pt.cmd.opc = NVME_OPC_RESERVATION_REGISTER
        pt.cmd.cdw10 = defs.htole32((irrega & 7) | (iiekey << 3) | (icptpl << 30))
        pt.buf = &data
        pt.len = sizeof(data)
        pt.is_read = 0

        with nogil:
            res = ioctl(self.fd, NVME_PASSTHROUGH_CMD, &pt)
            if res == -1:
                raise OSError('Register request failed')

            sc = NVME_STATUS_GET_SC(pt.cpl.status)
            st = NVME_STATUS_GET_SCT(pt.cpl.status)
            if sc != 0 or st != 0:
                raise OSError('Register request returned error')

        return True

    def resvrelease(self, crkey=0, rrela=0, rtype=0):
        cdef nvme_pt_command pt
        cdef uint64_t data[1]
        cdef uint32_t nsid
        cdef uint64_t icrkey = crkey
        cdef uint8_t irrela = rrela
        cdef uint8_t irtype = rtype

        data[0] = defs.htole64(icrkey)

        memset(&pt, 0, sizeof(pt))
        pt.cmd.opc = NVME_OPC_RESERVATION_RELEASE
        pt.cmd.cdw10 = defs.htole32((irrela & 7) | (irtype << 8))
        pt.buf = &data
        pt.len = sizeof(data)
        pt.is_read = 0

        with nogil:
            res = ioctl(self.fd, NVME_PASSTHROUGH_CMD, &pt)
            if res == -1:
                raise OSError('Release request failed')

            sc = NVME_STATUS_GET_SC(pt.cpl.status)
            st = NVME_STATUS_GET_SCT(pt.cpl.status)
            if sc != 0 or st != 0:
                raise OSError('Release request returned error')

        return True

    def resvreport(self):
        cdef nvme_pt_command pt
        cdef nvme_resv_status *s
        cdef uint8_t data[4096]
        cdef unsigned int i, n
        cdef bint eds = False

        bzero(data, sizeof(data))
        memset(&pt, 0, sizeof(pt))
        pt.cmd.opc = NVME_OPC_RESERVATION_REPORT
        pt.cmd.cdw10 = defs.htole32(sizeof(data) // 4 - 1)
        pt.cmd.cdw11 = defs.htole32(sizeof(eds))
        pt.buf = &data
        pt.len = sizeof(data)
        pt.is_read = 1

        with nogil:
            res = ioctl(self.fd, NVME_PASSTHROUGH_CMD, &pt)
            if res < 0:
                raise OSError('Report request failed')

            sc = NVME_STATUS_GET_SC(pt.cpl.status)
            st = NVME_STATUS_GET_SCT(pt.cpl.status)
            if sc != 0 or st != 0:
                raise OSError('Report request returned error')

        nvme_resv_status_swapbytes(<void *>data, sizeof(data))

        info = {}
        s = <nvme_resv_status *>data
        n = (s.regctl[1] << 8) | s.regctl[0]
        info['generation'] = s.gen
        info['scopetype'] = s.rtype
        info['number_of_registered_controllers'] = n
        info['persist_through_power_loss_state'] = s.ptpls
        info['controllers'] = []

        n = min(n, (sizeof(data) - sizeof(s)) // sizeof(s.ctrlr[0]))

        for i in range(n):
            info['controllers'].append(
                {
                    'controller_id': s.ctrlr[i].ctrlr_id,
                    'resv_status': s.ctrlr[i].rcsts,
                    'host_id': s.ctrlr[i].hostid,
                    'key': s.ctrlr[i].rkey,
                }
            )

        return info

    def read_reservation(self):
        """
        This function returns:
            1. the number of keys that
                have been put on the disk (generation)
            2. the type of reservation that
                is being held (scopetype)
            3. the reservation key that reserves
                the disk (reservation)
        """

        data = self.resvreport()

        for i in data['controllers']:
            if i['resv_status'] == 1:
                return {
                    'generation': data['generation'],
                    'scopetype': data['scopetype'],
                    'reservation': i['key'],
                }


    def read_keys(self):
        """
        This function returns:
            1. the number of keys that
                have been put on the disk (generation)
            2. the specific keys that
                have been put on the disk (keys)
        """

        data = self.resvreport()

        keys = []
        for i in data['controllers']:
            keys.append(i['key'])

        return {
            'generation': data['generation'],
            'keys': keys,
        }
